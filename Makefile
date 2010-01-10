# all (default)
#   Same as $ make dirs js skins www robots
#
# dirs
# 	Creates the required directories not present in git
#
# js
# 	Generates the Javascript code
#
# skins
# 	Generates the CSS code
#
# robots
# 	Ensures that www/robots.txt and static/robots.txt exist. Can be modified to
# 	suit your needs.
#
# chmod
# 	For when the http process is run from a different user than the files are
# 	chown'ed to. chmods all files and directories written to from vndb.pl.
# 	(including the stylesheets and javascript code, so these can be auto-updated)
#
# chmod-tladmin
# 	The TransAdmin plugin also needs write access to some files
#
# multi-start, multi-stop, multi-restart:
# 	Start/stop/restart the Multi daemon. Provided for convenience, a proper initscript
# 	probably makes more sense.
#
#	sql-import
#		Imports util/sql/all.sql into your (presumably empty) database
#
#	update-2.10
#		Updates all non-versioned items to 2.10
#
# NOTE: This Makefile has only been tested using a recent version of GNU make
#   in a relatively up-to-date Arch Linux environment, and may not work in other
#   environments. Patches to improve the portability are always welcome.


.PHONY: all dirs js skins robots chmod chmod-tladmin multi-start multi-stop multi-restart sql-import update-2.10

all: dirs js skins robots data/config.pl


dirs: static/cv static/sf static/st data/log www

static/cv static/sf static/st:
	mkdir $@;
	for i in $$(seq -w 0 1 99); do mkdir "$@/$$i"; done

data/log www:
	mkdir $@


js: static/f/script.js

static/f/script.js: data/script.js data/lang.txt util/jsgen.pl data/config.pl
	util/jsgen.pl


skins: static/s/*/style.css

static/s/%/style.css: static/s/%/conf util/skingen.pl data/style.css
	util/skingen.pl $*


robots: dirs www/robots.txt static/robots.txt

%/robots.txt:
	echo 'User-agent: *' > $@
	echo 'Disallow: /' >> $@


chmod: all
	chmod a-x+rw static/f/script.js
	chmod -R a-x+rwX static/{cv,sf,st}
	chmod a-x+rw static/s/*/{style.css,boxbg.png}

chmod-tladmin:
	chmod a-x+rwX data/lang.txt data/docs data/docs/*\.*


# may wait indefinitely, ^C and kill -9 in that case
define multi-stop
	if [ -s data/multi.pid ]; then\
	  kill `cat data/multi.pid`;\
	  while [ -s data/multi.pid ]; do\
	    if kill -0 `cat data/multi.pid`; then sleep 1;\
	    else rm -f data/multi.pid; fi\
	  done;\
	fi
endef

define multi-start
	util/multi.pl
endef

multi-stop:
	$(multi-stop)

multi-start:
	$(multi-start)

multi-restart:
	$(multi-stop)
	$(multi-start)


# Small perl script that tries to connect to the PostgreSQL database using 'psql', with the
# connection settings from data/config.pl. May not work in all configurations, though...
define runpsql
	perl -MDBI -e 'package VNDB;\
	$$ROOT=".";\
	require "data/global.pl";\
	$$_=(DBI->parse_dsn($$VNDB::O{db_login}[0]))[4];\
	$$ENV{PGPASSWORD} = $$VNDB::O{db_login}[2];\
	$$ENV{PGUSER}     = $$VNDB::O{db_login}[1];\
	$$ENV{PGDATABASE} = $$2 if /(dbname|db|database)=([^;]+)/;\
	$$ENV{PGHOST}     = $$1 if /host=([^;]+)/;\
	$$ENV{PGHOSTADDR} = $$1 if /hostaddr=([^;]+)/;\
	$$ENV{PGPORT}     = $$1 if /port=([^;]+)/;\
	$$ENV{PGSERVICE}  = $$1 if /service=([^;]+)/;\
	$$ENV{PGSSLMODE}  = $$1 if /sslmode=([^;]+)/;\
	open F, "|psql" or die $$!;\
	print F while(<>);\
	close F or exit 1'
endef


sql-import:
	${runpsql} < util/sql/all.sql


update-2.10: all
	$(multi-stop)
	@${runpsql} < util/updates/update_2.10.sql
	$(multi-start)

