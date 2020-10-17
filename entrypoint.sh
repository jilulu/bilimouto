#!/bin/sh -l

bili_video_url=$1
proxy_url=$2
bili_cookie=$3

you_get_cmd="you-get"
if [[ -n "$proxy_url" ]]; then
    you_get_cmd="$you_get_cmd -y $proxy_url $bili_video_url"
else
    you_get_cmd="$you_get_cmd $bili_video_url"
fi

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

echo $bili_cookie

echo "::set-output name=transfer_urls::$apple_optimized_output"