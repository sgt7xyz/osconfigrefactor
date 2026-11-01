![Debian Logo](images/debian.png) ![i3 Logo](images/i3.png)

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png"/></a><br/>This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.

# My Debian Tiling Install

This script is to automate as much as possible the post installation of my Debian system for a tiling window manager or provide instructions for personalization. As of right now It is still a work in progress and as things can be automated they will be moved from this README to the debianTilingSetup.sh script. Obviously you take this repository and modify it to your taste.

1. Clone this repository to your home directory.

```bash
cd ~
git clone git@github.com:sgt7xyz/my-tiling-sgt7.git
cd debian-tiling-sgt7
```

2. Select additional repositories and switch to fastest update server.

- Open "Software and Updates" => Debian Software Tab
  - Select additional repositories under the "Downloadable from the Internet" section.
  - Under "Download from" and select the best server for your locale.

3. Run the debianTilingSetup.sh script

```bash
$ chmod 700 debianTilingSetup.sh
$ ./debianTilingSetup.sh
```
