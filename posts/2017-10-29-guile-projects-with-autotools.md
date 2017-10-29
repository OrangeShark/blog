title: Setting up a GNU Guile project with Autotools
date: 2017-10-29 12:00
tags: gnu, guile, autotools
---

Lisp, specifically Scheme, has captivated me for about three years
now. My Scheme implementation of choice is [GNU Guile][guile] because
it is the official extension language of the [GNU project][gnu]. One issue I
faced early with when trying to develop for Guile was how to set up
and organize my project. There doesn't seem to be a single
recommended way to set up a Guile project but several projects do
follow a similar project structure I will describe below. You can find
a git repository with the example project [here][guile-skeleton].

## Simple Project Structure
The project template I created for new projects is based on several
GNU Guile projects I have examined. These projects follow the
traditional GNU Build System using the familiar commands `./configure
&& make && sudo make install` for building and installing software. To
help generate these files, we will use the collection of software
known as autotools which include the software [Autoconf][autoconf] and
[Automake][automake]. Unfortunately, autotools can be quite complex
for developers with its esoteric languages like m4 being used to
magically create and configure all the necessary build files for your
project. Good news for us, not much magic is needed for us to conjure
the build files for a simple Guile project.

```
.
├── bootstrap
├── configure.ac
├── COPYING
├── COPYING.LESSER
├── guile.am
├── m4
│   └── guile.m4
├── Makefile.am
├── skeleton
│   └── hello.scm
├── pre-inst-env.in
├── README
└── skeleton.scm
```

Above is the directory structure of the project. `bootstrap` is a
simple shell script which a developer can regenerate all the GNU Build
System files. `configure.ac` is a template file which Autoconf uses to
generate the familiar `configure` script. `m4/guile.m4` is a recent
copy of Guile's m4 macros, may not be needed if you prefer to use the
macro from your Guile distribution, but it is recommended to keep your
own copy. `COPYING` and `COPYING.LESSER` are just the GPL and LGPL
licenses. `Makefile.am` and `guile.am` are Automake files used to
generate the `Makefile.in` which `configure` will configure.
`skeleton.scm` and `skeleton/hello.scm` are some initial source code
files, where `skeleton.scm` represents the Guile module `(skeleton)`
and `skeleton/hello.scm` is the `(skeleton hello)` module, change
these file and directory names to what you want to name your modules
as. `pre-inst-env.in` is a shell script which set up environment
variables to be able to use your code before installing it.

## Bootstrapping the Project

```sh
#! /bin/sh

autoreconf --verbose --install --force
```

This is the `bootstrap` script, it just calls autoreconf, which uses
Autoconf and Automake, to generate the `configure` script from
`configure.ac` and `Makefile.in` file from `Makefile.am`. The
`bootstrap` script is sometimes also named `autogen.sh` in projects
but seems to no longer be preferred to avoid confusion with the [GNU
AutoGen project][autogen]. The command will also generate a bunch of
other files needed by the build process. This script is only used when
building from a checkout of the project's repository, because a user
will only need `configure` and `Makefile.in`. Whenever you might be
having an issue with the configure script or made a change to it,
doing `./bootstrap` will regenerate the files for you.

## Generating the Configure Script

```autoconf
AC_INIT([guile-skeleton], [0.1])
AC_CONFIG_SRCDIR([skeleton.scm])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

GUILE_PKG([2.2 2.0])
GUILE_PROGS
if test "x$GUILD" = "x"; then
   AC_MSG_ERROR(['guild' binary not found; please check your guile-2.x installation.])
fi

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env], [chmod +x pre-inst-env])

AC_OUTPUT
```

Above is the `configure.ac` file used by [GNU Autoconf][autoconf] to
generate the `configure` script. The first line is the `AC_INIT` macro,
the first argument is the package name and the second argument is the
version. There is a couple of other optional arguments which you can
learn more about [here][autoconf-configure]. The `AC_CONFIG_SRCDIR`
macro adds a check to `configure` for the existence of a unique file
in the source directory, useful as a safety check to make sure a user
is configuring the correct project. `AC_CONFIG_AUX_DIR` macro is where
auxiliary builds tools are found, `build-aux` is the the most commonly
used directory, we use this so we don't litter the source directory
with build tools.  The next macro, `AC_CONFIG_MACRO_DIR` is where
additional macros can be found, we add this to include the
`m4/guile.m4` file. [GNU Automake][automake] options are part of the
next macro, `AM_INIT_AUTOMAKE`, where `-Wall` turns all warnings,
`-Werror` turns those warnings into errors, and finally `foreign` will
turn the strictness to a standard less than the GNU standard. More
automake options can be found [here][automake-options].

The `GUILE_PKG` and `GUILE_PROGS` macro is part of the `m4/guile.m4`
file. This macro will substitute various variables that will be used
in the Makefile. The `GUILE_PKG` macro will use the pkg-config program
to find the development files for Guile and substitute the
`GUILE_EFFECTIVE_VERSION` variable in the Makefile. The `GUILE_PROGS`
macro finds the various Guile programs we will need to compile our
program. This macro substitutes the variables `GUILE` and `GUILD` with
the path to the `guile` and `guild` programs. By default, these
Guile macros will check for the latest version of Guile first, which
is currently 2.2. If you have multiple versions of Guile installed, a
user of the `configure` script may override the above Guile
variables. For example if you have Guile 2.2 and 2.0 installed and you
want to install the package for 2.0, you can run `./configure
GUILE=/path/to/guile2.0`. There is also a check to ensure the `GUILD`
variable was set by `GUILE_PROGS` and displayed an error if it could
not be found.

The next portion of this file involves the files that will actually be
configured when a user runs the `configure` script. The
`AC_CONFIG_FILES` macro's first argument is files that will be
created by substituting the variables found in the file of the same
name with `.in` appended to the end. In the first macro, it creates a
`Makefile` by substituting the variables in `Makefile.in`. The second
argument of this macro will be commands to run after the file is
created, in the second macro, it uses `chmod` to make the
`pre-inst-env` script executable. The last macro in this script is
`AC_OUTPUT` and must be the final macro in `configure.ac`. This macro
generates `config.status` and then uses it to do all the configuration.

## Generating the Project Makefile

For this project we use [GNU Automake][automake] to help us generate
the Makefile. When Automake is ran, it will produce a `Makefile.in`
file which will then be configured by the configure script. We divide
the Makefile into two files, `Makefile.am` and `guile.am`. The first
file is where we will put code specific for this project, that
includes source code and any other files to be distributed to
users. `guile.am` file is where we have all the code that can be
shared between any other Guile project.

```automake
include guile.am

SOURCES =               \
  skeleton/hello.scm    \
  skeleton.scm

EXTRA_DIST =            \
  README                \
  bootstrap             \
  pre-inst-env.in
```

This `Makefile.am` file is pretty small for now. The Automake script
first includes the Guile specific automake script `guile.am`. The next
part is the variable `SOURCES` which is a list of the project's source
code that will be compiled and installed. The next variable,
`EXTRA_DIST` is a list of other files that should be included in the
tarball used to distribute this project.

```automake
moddir=$(datadir)/guile/site/$(GUILE_EFFECTIVE_VERSION)
godir=$(libdir)/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache

GOBJECTS = $(SOURCES:%.scm=%.go)

nobase_dist_mod_DATA = $(SOURCES) $(NOCOMP_SOURCES)
nobase_go_DATA = $(GOBJECTS)

# Make sure source files are installed first, so that the mtime of
# installed compiled files is greater than that of installed source
# files.  See
# <http://lists.gnu.org/archive/html/guile-devel/2010-07/msg00125.html>
# for details.
guile_install_go_files = install-nobase_goDATA
$(guile_install_go_files): install-nobase_dist_modDATA

CLEANFILES = $(GOBJECTS)
GUILE_WARNINGS = -Wunbound-variable -Warity-mismatch -Wformat
SUFFIXES = .scm .go
.scm.go:
	$(AM_V_GEN)$(top_builddir)/pre-inst-env $(GUILD) compile $(GUILE_WARNINGS) -o "$@" "$<"

```

Now for `guile.am`, this file has all of the Guile specific code used
in our Automake scripts. The first two variables, `moddir` and
`godir`, are the paths where we will install our Guile modules and
compiled modules. The next variable is the `GOBJECTS` variable which
has some code that creates a list of Guile object files from our
`SOURCE` variable. The next two variables declared are special `DATA`
variables using some of Automake's features to indicate which files
should be installed and where. The first portion of the variable,
the `nobase_` prefix is used to tell Automake to not strip the path of
these files when installing them. `dist_` tells Automake that these
files must be distributed in the tarball. The next part, `mod_` or
`go_`, tell which directory these files should be installed, they
refer to the above `moddir` and `godir` variables. The files in
`SOURCES` and `NOCOMP_SOURCES` are installed in the `moddir`, where
`SOURCES` are the scheme files that we want to be compiled and the
`NOCOMP_SOURCES` are scheme files which should not be compiled. The
compiled Guile source code, `GOBJECTS` are installed in the
`godir`. The next two lines of code are some special magic to ensure
the files are installed in the right order by Automake. 

The `CLEANFILES` variable is an Automake variable with files which
should be deleted when a user runs `make clean`. The compiled Guile
modules are just the files we need to delete, so we assign
`GOBJECTS`. `GUILE_WARNINGS` are warnings we want to pass to Guile
when it compiles or executes the code. `SUFFIXES` allows us to add
Guile's `.scm` and `.go` file extensions to be handled by Automake and
we define a suffix rule on how to compile the source code using
`GUILD`.

## GNU Guile Project Source Files

We now get to the actual Guile code for this project. A Guile project
may be divided into several modules and organized in various ways. In
this skeleton project, the main module is the `skeleton` module and is
found in `skeleton.scm` file. Sub-modules of skeleton are found in the
`skeleton/` directory, where we currently have the `skeleton hello`
module found in the `skeleton/hello.scm` file.

```scheme
(define-module (skeleton)
  #:use-module (skeleton hello))

(hello-world)
```

This is the `skeleton` module, it defines the module with the
`define-module` form. We also import the `skeleton hello` module using
the `#:use-module` option of `define-module`. All this file does is
call `hello-world` procedure defined in the `skeleton hello` module.

```scheme
(define-module (skeleton hello)
  #:export (hello-world))

(define (hello-world)
  (display "Hello, World!"))
```

The final module is the `skeleton hello` module. This module defines
the `hello-world` procedure used in the previous module and then
exports it using the `#:exports` option in the `define-module` form.

## Putting It All Together

Now how does this all come together for development? With all these
files in place in the project, executing the command `./bootstrap`
will use Autoconf and Automake to generate the `configure`,
`Makefile.in`, and some other files. Then executing `./configure` will
configure `Makefile.in`, `pre-inst-env.in`. Running the program make
should now compile your source code.

```sh
#!/bin/sh

abs_top_srcdir="`cd "@abs_top_srcdir@" > /dev/null; pwd`"
abs_top_builddir="`cd "@abs_top_builddir@" > /dev/null; pwd`"

GUILE_LOAD_COMPILED_PATH="$abs_top_builddir${GUILE_LOAD_COMPILED_PATH:+:}$GUILE_LOAD_COMPILED_PATH"
GUILE_LOAD_PATH="$abs_top_builddir:$abs_top_srcdir${GUILE_LOAD_PATH:+:}:$GUILE_LOAD_PATH"
export GUILE_LOAD_COMPILED_PATH GUILE_LOAD_PATH

PATH="$abs_top_builddir:$PATH"
export PATH

exec "$@"
```

Above is the `pre-inst-env.in` file which is configured by the
configure script. The variables between '@' characters are variables
that will be replaced by the configure script. `abs_top_srcdir` and
`abs_top_builddir` are Autoconf variables which gives the absolute
source directory and build directory. Then we add these directories to
Guile's `GUILE_LOAD_COMPILED_PATH` and `GUILE_LOAD_PATH`.
`GUILE_LOAD_COMPILED_PATH` is an environment variable that has the
search path for compiled Guile code which have the `.go` extension.
`GUILE_LOAD_PATH` is the search path for Guile source code files. When
the configure script configures this file, it then allows you to run
Guile and use the modules of the project before installing them. This
can be done with this command `./pre-inst-env guile`. The script also
does the same for the `PATH` variable, to allow you to execute any
scripts in the project's directory. Finally, the script executes the
rest of the command passed into this script.

## Distributing the Project

So the project is now complete and you want to distribute it to other
people so they can build and install it. One of the great features of
autotools is it generates everything you need to distribute your
project. From the Makefile that is generated by GNU Automake, you run
`make dist` and it will generate a tar.gz file of your project. This
will be the file you will then give to your users and they will just
extract the contents and run `./configure && make && sudo make install` to build and
install your project. The files that are included in the distribution
are figured out by Automake and can be added to in your `Makefile.am`
script file using the `EXTRA_DIST` variable. One other helpful feature
that GNU Automake will generate is the command `make distcheck`. This
command will check to ensure the distribution actually works, it will
first create a distribution and then proceed to open the distribution, build
the project, run tests, install the project, and uninstall the project
all in a temporary directory. You can learn more about GNU Automake
distribution in the [manual][automake-dist].

One more note about installing your GNU Guile project. By default, the
GNU Build System installs your project in the `/usr/local`
directory. GNU Guile installations generally do not have this
directory on their load path. There are several options on how to
resolve this issue. You can add
`/usr/local/share/guile/site/$(GUILE_EFFECTIVE_VERSION)` to the
`GUILE_LOAD_PATH` variable as well as
`/usr/local/lib/guile/$(GUILE_EFFECTIVE_VERSION)/site-ccache` to the
`GUILE_COMPILED_LOAD_PATH` variable, where
`$(GUILE_EFFECTIVE_VERSION)` is the GNU Guile version you are using,
like 2.0 or 2.2. You can add these variables to your `.profile` or
`.bash_profile` in your home directory like so:

```bash
export GUILE_LOAD_PATH="/usr/local/share/guile/site/2.2${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
export GUILE_LOAD_COMPILED_PATH="/usr/local/lib/guile/2.2/site-cacche${GUILE_LOAD_COMPILED_PATH:+:}$GUILE_COMPILED_LOAD_PATH"
```

The alternative is to install your project in the current load path of
your GNU Guile installation which is often `/usr`. You can easily do
this by changing the `prefix` variable in the configure script like
`./configure prefix=/usr`. Now when you run `make install` it will
install everything in `/usr` instead of `/usr/local`. With the GNU
Build System, you have full control of where you install your Guile
files so you have the possibility of installing it anywhere you want
like your home directory, just be sure to add that location to your
load paths for Guile. There are several other variables you can modify
to change the installation location of various files, you can learn
more in the [GNU Autoconf manual][autoconf-dir-vars].

## Conclusion

The GNU Build System provides a common interface for configuring,
building, and installing software. The autotools project, although a
bit complex, helps us achieve this. This should be enough for a basic
GNU Guile library that can be compiled and distributed to users using
the GNU Build System. You can find the example project on GitLab
[here][guile-skeleton]. The project can be extended to include tests
and documentation that I hope to cover in other blog posts.

[guile]: https://www.gnu.org/software/guile/ "GNU Ubiquitous Intelligent Language for Extensions"
[autoconf]: https://www.gnu.org/software/autoconf/autoconf.html
[automake]: https://www.gnu.org/software/automake/
[autoconf-configure]: https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.69/html_node/Initializing-configure.html#Initializing-configure
[automake-options]: https://www.gnu.org/software/automake/manual/html_node/List-of-Automake-options.html#List-of-Automake-options
[guile-skeleton]: https://gitlab.com/OrangeShark/guile-skeleton
[automake-dist]: https://www.gnu.org/software/automake/manual/automake.html#Dist
[autoconf-dir-vars]: https://www.gnu.org/savannah-checkouts/gnu/autoconf/manual/autoconf-2.69/html_node/Installation-Directory-Variables.html#Installation-Directory-Variables
[gnu]: https://www.gnu.org/
[autogen]: https://www.gnu.org/software/autogen/
