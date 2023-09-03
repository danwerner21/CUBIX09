all:
	$(MAKE) --directory nhyodyne
	$(MAKE) --directory cubix_os

pretty:
	$(MAKE) --directory nhyodyne pretty
	$(MAKE) --directory cubix_os pretty

clean:
	$(MAKE) --directory nhyodyne pretty
	$(MAKE) --directory cubix_os pretty
