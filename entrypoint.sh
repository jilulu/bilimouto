#!/bin/sh -l

bili_video_url=$1
proxy_url=$2
bili_cookie_b64=$3

you_get_cmd="you-get"
if [[ -n "$proxy_url" ]]; then
    you_get_cmd="$you_get_cmd -y $proxy_url"
fi
if [[ -n "$bili_cookie_b64" ]]; then 
    echo "$bili_cookie_b64" | base64 -d > cookies.txt
    you_get_cmd="$you_get_cmd -c cookies.txt"
fi
you_get_cmd="$you_get_cmd $bili_video_url"

echo "Fetching Bilibili video with you-get"
echo "$you_get_cmd"
you_get_output=$(eval $you_get_cmd | grep "Merging video parts... Merged into " | sed "s/Merging video parts... Merged into //")
if [[ -z "$you_get_output" ]]; then 
    echo >&2 "Failed to download $bili_video_url with you-get"
    exit 1
fi
if ffprobe "$you_get_output" 2>&1 | grep "Video: hevc"; then
    echo "Optimizing hevc video for Apple devices: adding hvc1 tag"
    apple_optimized_output=$(echo "$you_get_output" | sed "s/.mp4/.hvc1-tagged.mp4/")
    ffmpeg -i "$you_get_output" -c copy -tag:v hvc1 -hide_banner -loglevel panic "$apple_optimized_output" 
else 
    apple_optimized_output="$you_get_output"
fi

download_link=$(transfer wet --silent "$apple_optimized_output")

echo "::set-output name=transfer_urls::$download_link"