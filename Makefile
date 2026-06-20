ANSIBLE_DIR=ansible
PLAYBOOK=$(ANSIBLE_DIR)/site.yml
INVENTORY=$(ANSIBLE_DIR)/inventories/local/hosts.yml
ANSIBLE_CONFIG=$(ANSIBLE_DIR)/ansible.cfg
ENV_FILE=if [ -f .env ]; then set -a; . ./.env; set +a; fi;

.PHONY: deps lint check apply idempotence

deps:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

lint:
	bash -lc '$(ENV_FILE) ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" LANG=C ansible-playbook --syntax-check -i $(INVENTORY) $(PLAYBOOK)'

check:
	@bash -lc 'read -rsp "BECOME password: " pw; echo; $(ENV_FILE) ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" LANG=C ansible-playbook -e "ansible_become_password=$$pw" --check --diff -i $(INVENTORY) $(PLAYBOOK)'

apply:
	@bash -lc 'read -rsp "BECOME password: " pw; echo; $(ENV_FILE) ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" LANG=C ansible-playbook -e "ansible_become_password=$$pw" -i $(INVENTORY) $(PLAYBOOK)'

idempotence:
	@bash -lc 'read -rsp "BECOME password: " pw; echo; $(ENV_FILE) ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" LANG=C ansible-playbook -e "ansible_become_password=$$pw" -i $(INVENTORY) $(PLAYBOOK); $(ENV_FILE) ANSIBLE_CONFIG="$(ANSIBLE_CONFIG)" LANG=C ansible-playbook -e "ansible_become_password=$$pw" -i $(INVENTORY) $(PLAYBOOK)'
