ANSIBLE_DIR=ansible
PLAYBOOK=$(ANSIBLE_DIR)/site.yml
INVENTORY=$(ANSIBLE_DIR)/inventories/local/hosts.yml
ENV_RUN=if [ -f .env ]; then set -a; . ./.env; set +a; fi; 
BECOME_FLAG?=--ask-become-pass
ANSIBLE_RUN=LANG=C ansible-playbook

.PHONY: deps lint check apply idempotence

deps:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

lint:
	bash -lc '$(ENV_RUN) $(ANSIBLE_RUN) --syntax-check -i $(INVENTORY) $(PLAYBOOK)'

check:
	bash -lc '$(ENV_RUN) $(ANSIBLE_RUN) $(BECOME_FLAG) --check --diff -i $(INVENTORY) $(PLAYBOOK)'

apply:
	bash -lc '$(ENV_RUN) $(ANSIBLE_RUN) $(BECOME_FLAG) -i $(INVENTORY) $(PLAYBOOK)'

idempotence:
	bash -lc '$(ENV_RUN) $(ANSIBLE_RUN) $(BECOME_FLAG) -i $(INVENTORY) $(PLAYBOOK)'
	bash -lc '$(ENV_RUN) $(ANSIBLE_RUN) $(BECOME_FLAG) -i $(INVENTORY) $(PLAYBOOK)'
