.PHONY: test

test:
	@for t in tests/*.lua; do printf '\n%s\n' "$$t"; nvim --headless -u NONE -l "$$t" || exit 1; done; echo
