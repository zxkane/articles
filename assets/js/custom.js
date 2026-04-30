/* Post-process theme-generated artifacts for accessibility. */
(function () {
  function annotateHeadingAnchors() {
    document.querySelectorAll('.post_content a.link.icon').forEach(function (a) {
      if (a.getAttribute('aria-label')) return;
      var heading = a.closest('h1, h2, h3, h4, h5, h6');
      var title = heading ? (heading.textContent || '').trim() : '';
      a.setAttribute('aria-label', title ? ('Permalink to section: ' + title) : 'Permalink to section');
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', annotateHeadingAnchors);
  } else {
    annotateHeadingAnchors();
  }
})();
