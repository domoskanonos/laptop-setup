ANSIBLE_DIR=ansible
PLAYBOOK=$(ANSIBLE_DIR)/site.yml
INVENTORY=$(ANSIBLE_DIR)/inventories/local/hosts.yml
ENV_RUN=if [ -f .env ]; then set -a; . ./.env; set +a; fi; 

.PHONY: deps lint check apply idempotence

deps:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

lint:
	bash -lc '$(ENV_RUN) ansible-playbook --syntax-check -i $(INVENTORY) $(PLAYBOOK)'

check:
	sudo -v
	bash -lc '$(ENV_RUN) ansible-playbook --check --diff -i $(INVENTORY) $(PLAYBOOK)'

apply:
	sudo -v
	bash -lc '$(ENV_RUN) ansible-playbook -i $(INVENTORY) $(PLAYBOOK)'

idempotence:
	sudo -v
	bash -lc '$(ENV_RUN) ansible-playbook -i $(INVENTORY) $(PLAYBOOK)'
	bash -lc '$(ENV_RUN) ansible-playbook -i $(INVENTORY) $(PLAYBOOK)'
