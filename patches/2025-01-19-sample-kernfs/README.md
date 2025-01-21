# Simple pseudo-filesystem sample build on top of `kernfs`

I'm working in my own `linux` tree in a branch called `davidreaver/sample-kernfs` and is located at <https://github.com/jdreaver/linux/tree/davidreaver/sample-kernfs> (diff URL: <https://github.com/jdreaver/linux/compare/master...jdreaver:linux:davidreaver/sample-kernfs>). I'm storing patches in this directory with:

```sh
cd ~/git/kernel-dev/linux
git switch davidreaver/sample-kernfs
rm -f ../patches/2025-01-19-sample-kernfs/*.patch && git format-patch master...HEAD --base=origin/master -o ../patches/2025-01-19-sample-kernfs/ --cover-letter
```

## git send-email

For future me, if you are looking at this directory as an example: don't mess up `git send-email` with a patch series. What I did wrong:

- I manually added To and Cc addresses in the cover letter, which I have done in the past for single patches (not series). I liked this because `git send-email` reads it and I don't need to remember to set it on the command line.
- However, the subsequent patches were _missing_ these addresses. When I sent the whole series, the cover letter went to the mailing list, and all the other emails just went to me.
- I had to scramble to find the proper `In-Reply-To:` ID from lore and resend everything but the cover letter.

In the future, add the `--to` and `--cc` arguments to `git format-patch`. I can keep the command in a README like this one to make it easier. `git send-email` should automatically thread replies. _However_, maybe wait a bit after sending the first patch and ensure the cover letter ends up on kernel lore first so the `In-Reply-To` ID is "present" (this might be paranoia).

## Communication

First patch series posted to mailing lists: <https://lore.kernel.org/linux-fsdevel/20250121153646.37895-1-me@davidreaver.com/T/#u>
