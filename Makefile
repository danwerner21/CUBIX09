all:
	$(MAKE) --directory monitor
	$(MAKE) --directory cubix_os
	$(MAKE) --directory duodyne
	$(MAKE) --directory nhyodyne
	$(MAKE) --directory cubix_util

pretty:
	$(MAKE) --directory monitor pretty
	$(MAKE) --directory nhyodyne pretty
	$(MAKE) --directory duodyne pretty
	$(MAKE) --directory cubix_os pretty
	$(MAKE) --directory cubix_util pretty

clean:
	$(MAKE) --directory monitor clean
	$(MAKE) --directory nhyodyne clean
	$(MAKE) --directory duodyne clean
	$(MAKE) --directory cubix_os clean
	$(MAKE) --directory cubix_util clean
