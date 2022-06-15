fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

setup-git-hooks:
	rm -rf .git/hooks
	(cd .git && ln -s ../.git-hooks hooks)

tf-providers-lock:
	terraform providers lock \
		-platform=windows_amd64 \
		-platform=darwin_amd64 \
		-platform=darwin_arm64 \
		-platform=linux_amd64
	git add .terraform.lock.hcl
	git commit -m "[auto] chore(terraform): Lock providers to .terraform.lock.hcl" .terraform.lock.hcl
