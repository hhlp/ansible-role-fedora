.PHONY: requirements syntax lint check apply list-tags

requirements:
	ansible-galaxy collection install -r requirements.yml -p .ansible/collections

syntax:
	ansible-playbook --syntax-check site.yml

lint:
	yamllint .
	ansible-lint

check:
	ansible-playbook site.yml --check --diff --ask-become-pass

apply:
	ansible-playbook site.yml --ask-become-pass

list-tags:
	ansible-playbook site.yml --list-tags
