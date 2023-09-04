all:
	$(MAKE) --directory nhyodyne
	$(MAKE) --directory cubix_os
	$(MAKE) --directory cubix_util

pretty:
	$(MAKE) --directory nhyodyne pretty
	$(MAKE) --directory cubix_os pretty
	$(MAKE) --directory cubix_util pretty

clean:
	$(MAKE) --directory nhyodyne clean
	$(MAKE) --directory cubix_os clean
	$(MAKE) --directory cubix_util clean
