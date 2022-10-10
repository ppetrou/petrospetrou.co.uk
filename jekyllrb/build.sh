sudo podman run --name petrospetrou.co.uk --rm --volume="$PWD/root:/srv/jekyll:Z" -it jekyll/jekyll:4.2.0 jekyll build
