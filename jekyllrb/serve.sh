sudo podman run --name petrospetrou.co.uk --rm --volume="$PWD/root:/srv/jekyll:Z" -p 4000:4000 -it jekyll/jekyll:4.2.0 jekyll serve
