#!/bin/bash

######################
# USER CONFIGURATION #
######################

# Path to image directory (relative to the path from which you run this script)
image_dir="./content" # No trailing slash

# Opt-in to individual actions
optimize_images=true       # Requires Imagemagick v7+ https://imagemagick.org/
optimize_images_scale=true # Whether to scale images to a maximum width of 1000px
create_webp=true           # Requires cwebp https://developers.google.com/speed/webp/docs/cwebp
create_avif=true           # Requires avif-cli https://github.com/lovell/avif-cli

# Note on image optimization:
#
# As noted above, this script uses Imagemagick for image optimization.
# Imagemagick will recompress an image every time optimization is run, even if
# it's been done before. This means the operation is not idempotent and will
# result in new versions of old (already-optimized) files. If this bothers you,
# alternative tools that could perform optimization include exiv2, exiftool,
# or format-specific tools like jpegtran and pngquant.
# References:
# https://legacy.imagemagick.org/discourse-server/viewtopic.php?f=3&t=10895
# https://stackoverflow.com/q/2654281
#
# For a fuller version of this script that is configurable at the command-line,
# see:
# https://github.com/rootwork/bash-scripts/blob/main/images/modimg.sh

##########
# SCRIPT #
##########

shopt -s nullglob # Globs that match nothing expand to nothing
shopt -s globstar # ** matches multiple directory levels

# Ansi color code variables
green="\e[0;92m"
blue="\e[0;94m"
expand_bg="\e[K"
red_bg="\e[0;101m${expand_bg}"
reset="\e[0m"

if [[ $optimize_images = "true" ]]; then
  # Optimize png, jpg, gif

  magick=$(command -v magick)
  if [[ ! $magick ]]; then
    echo -e "${red_bg}Error: Imagemagick is not installed. Aborting.${reset}\n" >&2
    exit 1
  fi

  echo -e "\n${green}Optimizing images in content...${reset}"

  for f in "$image_dir"/**/*.{jpg,jpeg,png,gif}; do
    if [ -e "$f" ]; then
      if [[ $optimize_images_scale = "true" ]]; then
        "$magick" mogrify -strip -thumbnail '1000>' "$f"
      else
        "$magick" mogrify -strip "$f"
      fi
      echo -e "${blue}${f}${reset}"
    fi
  done
  echo -e "${green}                                ...done.${reset}"
fi

if [[ $create_webp = "true" ]] || [[ $create_avif = "true" ]]; then

  echo -e "\n${green}Creating modern image formats...${reset}"

  if [[ $create_webp = "true" ]]; then
    # Create webp from jpeg and png files; gif files are likely to be larger in webp
    # https://developers.google.com/speed/webp/docs/cwebp

    cwebp=$(command -v cwebp)
    if [[ ! $cwebp ]]; then
      echo -e "${red_bg}Error: cwebp is not installed. Aborting.${reset}\n" >&2
      exit 1
    fi

    for f in "$image_dir"/**/*.{jpg,jpeg,png}; do
      newfile="${f%.*}.webp"
      if [ -e "$f" ]; then
        if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist
          "$cwebp" -quiet "$f" -o "${newfile}"
          echo -e "${blue}${newfile}${reset}"
        fi
      fi
    done
  fi

  if [[ $create_avif = "true" ]]; then
    # Create avif from webp files, and any gif files
    # https://github.com/lovell/avif-cli

    npx=$(command -v npx)
    if [[ ! $npx ]]; then
      echo -e "${red_bg}Error: npx is not installed and is required to run avif-cli. Aborting.${reset}\n" >&2
      exit 1
    fi

    avif=$(command -v avif)
    if [[ ! $avif ]]; then
      echo -e "${red_bg}Error: avif-cli is not installed. Aborting.${reset}\n" >&2
      exit 1
    fi

    for f in "$image_dir"/**/*.{webp,gif}; do
      newfile="${f%.*}.avif"
      if [ -e "$f" ]; then
        if [ ! -e "${newfile}" ]; then # Create only if file doesn't exist
          dir="$(dirname "${f}")"
          "$npx" "$avif" --input="$f" --output="$dir"
          echo -e "${blue}${newfile}${reset}"
        fi
      fi
    done
  fi

  echo -e "${green}                                ...done.${reset}\n"

fi
