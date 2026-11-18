#!/usr/bin/env python3
"""Exercise the real Hugo image partials against controlled HTTP responses."""

import binascii
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from html.parser import HTMLParser
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import threading
import unittest
import zlib


ROOT = Path(__file__).resolve().parents[1]


def png_chunk(kind, data):
    return (struct.pack(">I", len(data)) + kind + data
            + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF))


PNG = (b"\x89PNG\r\n\x1a\n"
       + png_chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 3, 8, 6, 0, 0, 0))
       + png_chunk(b"IDAT", zlib.compress((b"\0" + b"\xff\0\0\xff" * 2) * 3))
       + png_chunk(b"IEND", b""))


class ImageServer(BaseHTTPRequestHandler):
    def do_GET(self):
        status = {"/ok.png": 200, "/missing.png": 404,
                  "/denied.png": 403, "/unavailable.png": 503}.get(self.path, 404)
        self.send_response(status)
        self.send_header("Content-Type", "image/png" if status == 200 else "text/plain")
        self.end_headers()
        self.wfile.write(PNG if status == 200 else b"Image unavailable")

    def log_message(self, *args):
        pass


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.images = []

    def handle_starttag(self, tag, attrs):
        if tag == "img":
            self.images.append(dict(attrs))


class RemoteImagesTest(unittest.TestCase):
    def test_remote_images_do_not_abort_the_site_build(self):
        server = ThreadingHTTPServer(("127.0.0.1", 0), ImageServer)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory(prefix="hugo-remote-images-") as directory:
                site = Path(directory)
                partials = site / "layouts/partials"
                partials.mkdir(parents=True)
                for name in ["image.html", "figure.html"]:
                    shutil.copyfile(ROOT / "layouts/partials" / name, partials / name)
                (site / "hugo.toml").write_text(
                    'baseURL = "https://example.com/"\n'
                    'timeout = "2s"\n'
                    'disableKinds = ["home", "taxonomy", "term", "RSS", "sitemap"]\n'
                    '[params]\nimagesDir = "images"\nusePageBundles = true\n')
                (site / "layouts/_default").mkdir()
                (site / "layouts/_default/single.html").write_text(
                    '{{ partial "image" (dict "file" .Params.testImage '
                    '"alt" .Title "type" "thumbnail" "Page" .) }}')
                cases = []
                for bundled in [True, False]:
                    for image in ["ok", "missing", "denied", "unavailable"]:
                        name = f"{image}-{bundled}"
                        url = f"http://127.0.0.1:{server.server_port}/{image}.png"
                        page = site / "content" / name
                        page.mkdir(parents=True)
                        (page / "index.md").write_text(
                            '---\n' + json.dumps({"title": name, "testImage": url,
                                                 "usePageBundles": bundled}) + '\n---\n')
                        cases.append((name, image, url))
                result = subprocess.run(
                    ["hugo", "--source", str(site), "--cacheDir", str(site / "cache")],
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
                self.assertEqual(result.returncode, 0, result.stdout)
                for name, image, url in cases:
                    with self.subTest(image=image, page=name):
                        parsed = Images()
                        parsed.feed((site / "public" / name.lower() / "index.html").read_text())
                        self.assertEqual(len(parsed.images), 1)
                        attributes = parsed.images[0]
                        if image == "ok":
                            self.assertIn("image_processed", attributes["class"])
                            self.assertEqual((attributes["width"], attributes["height"]), ("2", "3"))
                            self.assertTrue(attributes["src"].startswith("https://example.com/"))
                        else:
                            self.assertIn("image_unprocessed", attributes["class"])
                            self.assertEqual(attributes["src"], url)
                            self.assertEqual((attributes["width"], attributes["height"]), ("1200", "630"))
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
