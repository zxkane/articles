---
title: '[tip]Find -exec tip'
date: 2010-02-24T13:46:00.001+08:00
lastmod: 2024-01-07
draft: false
tags : [Shell]
---

Using -exec command like below, need add escape character for semicolon that separated two commands in shell  

{{< highlight bash >}}
find directory/ -type d -exec chmod a+x {} \\;  
{{< /highlight >}}

> Feb 24, 2010 - update:

{{< highlight bash >}}
find . -maxdepth 4 -type d  -name 'g-vxworks' 2>/dev/null -print
{{< /highlight >}}

> Jan. 7, 2024 - update:
You might see `No such file or directory` when combining `--exec rm` to delete the found files.

You can add `-depth` option to mitigate the message.

{{< highlight bash >}}
find deployment/g -depth -name 'asset.*' -type d -exec rm -rf {} \;
{{< /highlight >}}