TARGET ?= ck_UID

.PHONY: target
target:
	vagrant docker-exec -t -- su - vagrant -c 'source /vagrant/jhalfs/jhalfs.sh && cd $$LFS/jhalfs && make $(TARGET)'
