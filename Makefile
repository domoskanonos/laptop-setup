ANSIBLE_DIR=ansible
PLAYBOOK=$(ANSIBLE_DIR)/site.yml
INVENTORY=$(ANSIBLE_DIR)/inventories/local/hosts.yml
ENV_FILE=if [ -f .env ]; then set -a; . ./.env; set +a; fi;
# Passwort einmalig per read abfragen und als Env-Variable uebergeben:
# - vermeidet PTY/sudo-Prompt-Matching-Probleme
# - @ unterdrueckt die Zeile im Output (kein Passwortverlust in Logs)
RUN_PLAYBOOK=@bash -c 'read -rsp "BECOME password: " pw; echo; $(ENV_FILE) LANG=C ANSIBLE_BECOME_PASSWORD="$$pw" ansible-playbook

.PHONY: deps lint check apply idempotence

deps:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

lint:
	bash -lc '$(ENV_FILE) LANG=C ansible-playbook --syntax-check -i $(INVENTORY) $(PLAYBOOK)'

check:
	$(RUN_PLAYBOOK) --check --diff -i $(INVENTORY) $(PLAYBOOK)'

apply:
	$(RUN_PLAYBOOK) -i $(INVENTORY) $(PLAYBOOK)'

idempotence:
	$(RUN_PLAYBOOK) -i $(INVENTORY) $(PLAYBOOK)'
	$(RUN_PLAYBOOK) -i $(INVENTORY) $(PLAYBOOK)'
