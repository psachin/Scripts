MAKEFILES FOR XILINX FPGA/CPLD PROJECTS
    These makefiles were created so that you can develop a Xilinx project
    using the WebPACK/ISE GUI, but then use a makefile to automate the build
    process once the development work is done.

    Several makefiles will be described:

    "Xilinx Rules Makefile"
        This makefile contains the rules that move the HDL files through the
        synthesizer, place & route and bitstream generation processes to
        produce the final bitstream file.

    "Project Makefile"
        This makefile resides in the WebPACK/ISE project directory and uses
        the Xilinx rules makefile to create the bitstream for the project.

    "Directory Makefile"
        This makefile creates bitstreams for a number WebPACK/ISE projects
        by calling the project makefile in each of the project
        subdirectories.

  Xilinx Rules Makefile
    The xilinx_rules.mk file contains the variable definitions and rules
    that perform the bulk of the operations for creating an FPGA or CPLD
    configuration bitstream. The rules encode the process flow for an FPGA:

      (.vhd,.ver)-->[XST]-->(.ngc,.ucf)-->[NGDBUILD]-->(.ngd,.pcf)-->[MAP]-->(.ncd,.pcf)--> ...
                ... -->[PAR]-->(.ncd)-->[BITGEN]-->(.bit)

    and the process flow for a CPLD:

      (.vhd,.ver)-->[XST]-->(.ngc,.ucf)-->[NGDBUILD]-->(.ngd)-->[CPLDFIT]-->(.vm6)--> ...
                ... -->[HPREP6]-->(.jed)-->[IMPACT]-->(.svf)

    xilinx_rules.mk is not used directly. It is included in the main
    makefile of a WebPACK/ISE project. xilinx_rules.mk is usually placed in
    the /usr/local/include directory so that "make" can find it when needed.

    The xilinx_rules.mk file is shown below. xilinx_rules.mk uses several
    Perl script files (get_option_values.pl, set_option_values.pl, and
    get_project_files.pl) and these are also shown.

   xilinx_rules.mk
            #-------------------------------------------------------------------
            # Company       : XESS Corp.
            # Engineer      : Dave Vanden Bout
            # Creation Date : 05/16/2006
            # Copyright     : 2005-2006, XESS Corp
            # Tool Versions : make 3.79.1, perl 5.8.8, WebPACK 8.1.03i
            #
            # Description:
            #    This makefile contains the rules that move the HDL files through
            #    the Xilinx WebPACK/ISE synthesizer, place & route and bitstream 
            #    generation processes to produce the final bitstream file.
            #
            # Revision:
            #    1.0.3
            #
            # Additional Comments:
            #    This file is normally included in another makefile using the
            #    `include' directive.  Usually this file is placed in the 
            #    /usr/local/include directory so make can find it automatically.
            #
            #    The makefile targets are:
            #        config: Creates bit/svf file for FPGA/CPLD.
            #        svf:    Directly creates bit file for FPGA.
            #        bit:    Directly creates svf file for CPLD.
            #        mcs:    Creates Intel MCS file from bit file.
            #        exo:    Creates Motorola EXO file from bit file.
            #        timing: Creates timing report for FPGA (not CPLD).
            #        clean:  Cleans temporary files created during build process.
            #        distclean: Clean and also remove timing report.
            #        maintainer-clean: Distclean and also remove bit/svf files.
            #        nice:   beautify the HDL source code
            #
            #    1.0.3:
            #        Modified to support ISE9 project directory structure.
            #    1.0.2:
            #        Added more file types for removal during cleaning.
            #    1.0.1:
            #        Added 'nice' target.
            #    1.0.0
            #        Initial revision.
            #-------------------------------------------------------------------

            #
            # Paths to utilities.
            #

            # Standard OS utilities.  These are for DOS.  Set them for your particular OS.
            RM                 := erase /s /q
            RMDIR              := rmdir /s /q
            MKDIR              := mkdir
            ECHO               := echo
            EMACS              := /bin/emacs-21.3/bin/emacs

            # These are Perl script files that perform some simple operations.
            UTILITY_DIR        := C:/BIN/
            SET_OPTION_VALUES  := perl $(UTILITY_DIR)set_option_values.pl
            GET_OPTION_VALUES  := perl $(UTILITY_DIR)get_option_values.pl
            GET_PROJECT_FILES  := perl $(UTILITY_DIR)get_project_files.pl

            #
            # Flags and option values that control the behavior of the Xilinx tools.
            # You can override these values in the makefile that includes this one.
            # Otherwise, the default values will be set as shown below.
            #

            # Unless otherwise specified, the name of the design and the top-level
            # entity are derived from the name of the directory that contains the design.
            DIR_SPACES  := $(subst /, ,$(CURDIR))
            DIR_NAME    := $(word $(words $(DIR_SPACES)), $(DIR_SPACES))
            DESIGN_NAME ?= $(DIR_NAME)
            TOP_NAME    ?= $(DESIGN_NAME)

            # Extract the part identifier from the project .npl file.
            PART_TYPE        ?=            $(shell $(GET_OPTION_VALUES) $(DESIGN_NAME).npl DEVICE)
            PART_SPEED_GRADE ?= $(subst -,,$(shell $(GET_OPTION_VALUES) $(DESIGN_NAME).npl DEVSPEED))
            PART_PACKAGE     ?=            $(shell $(GET_OPTION_VALUES) $(DESIGN_NAME).npl DEVPKG)
            PART             ?= $(PART_TYPE)-$(PART_SPEED_GRADE)-$(PART_PACKAGE)

            # This variable will be non-empty if the design is targeted to an XC9500 CPLD.
            IS_CPLD = $(findstring xc95,$(PART))

            # Flags common to both FPGA and CPLD design flow.
            INTSTYLE         ?= -intstyle silent      # call Xilinx tools in silent mode
            XST_FLAGS        ?= $(INTSTYLE)           # most synthesis flags are specified in the .xst file
            UCF_FILE         ?= $(DESIGN_NAME).ucf    # constraint/pin-assignment file
            NGDBUILD_FLAGS   ?= $(INTSTYLE) -dd _ngo  # ngdbuild flags
            NGDBUILD_FLAGS += $(if $(UCF_FILE),-uc,) $(UCF_FILE)         # append the UCF file option if it is specified 

            # Flags for FPGA-specific tools.  These were extracted by looking in the
            # .cmd_log file after compiling the design with the WebPACK/ISE GUI.
            MAP_FLAGS        ?= $(INTSTYLE) -cm area -pr b -k 4 -c 100 -tx off
            PAR_FLAGS        ?= $(INTSTYLE) -w -ol std -t 1
            TRCE_FLAGS       ?= $(INTSTYLE) -e 3 -l 3
            BITGEN_FLAGS     ?= $(INTSTYLE)           # most bitgen flags are specified in the .ut file
            PROMGEN_FLAGS    ?= -u 0                  # flags that control the MCS/EXO file generation

            # Flags for CPLD-specific tools.  These were extracted by looking in the
            # .cmd_log file after compiling the design with the WebPACK/ISE GUI.
            CPLDFIT_FLAGS    ?= -ofmt vhdl -optimize speed -htmlrpt -loc on -slew fast -init low -inputs 54 -pterms 25 -unused float -power std -terminate keeper
            SIGNATURE        ?= $(DESIGN_NAME)        # JTAG-accessible signature stored in the CPLD
            HPREP6_FLAGS     ?= -s IEEE1149           # hprep flags
            HPREP6_FLAGS     += $(if $(SIGNATURE),-n,) $(SIGNATURE)  # append signature if it is specified 

            # Determine the version of Xilinx ISE that is being used by reading it from the
            # readme.txt file in the top-level directory of the Xilinx software.
            ISE_VERSION ?= $(shell grep -m 1 -o -P "ISE\s*[0-9]+" %XILINX%/readme.txt | grep -m 1 -P -o "[0-9]+")
            ifeq ($(ISE_VERSION),6)
                    PROJNAV_DIR ?= __projnav
            else
            ifeq ($(ISE_VERSION),7)
                    PROJNAV_DIR ?= __projnav
            else
                    PROJNAV_DIR ?= .
            endif
            endif

            # Select the correct tool options files that control the synthesizer
            # and bitstream generator for FPGAs or CPLDs.
            ifneq (,$(IS_CPLD))
                    XST_CPLD_OPTIONS_FILE ?= $(PROJNAV_DIR)/$(DESIGN_NAME).xst
                    IMPACT_OPTIONS_FILE   ?= _impact.cmd
                    XST_OPTIONS_FILE       = $(XST_CPLD_OPTIONS_FILE)
            else
                    XST_FPGA_OPTIONS_FILE ?= $(PROJNAV_DIR)/$(DESIGN_NAME).xst
                    BITGEN_OPTIONS_FILE   ?= $(DESIGN_NAME).ut
                    XST_OPTIONS_FILE       = $(XST_FPGA_OPTIONS_FILE)
            endif

            #
            # The following rules describe how to compile the design to an FPGA/CPLD.
            #

            # Get the list of VHDL and Verilog files that this design depends on by
            # extracting their names from the project .prj file.  This variable is used
            # by make for checking dependencies, but the synthesizer tool ignores this
            # variable and uses the file list found in the .prj file.
            ifeq ($(origin HDL_FILES),undefined)
              HDL_FILES       ?= $(shell $(GET_PROJECT_FILES) $(DESIGN_NAME).prj)
            endif

            # cleanup the source code to make it look nice
            %.nice: %.vhd
                    $(EMACS) -batch $< -f vhdl-beautify-buffer -f save-buffer
                    $(RM) $<~

            # Synthesize the HDL files into an NGC file.  This rule is triggered if
            # any of the HDL files are changed or the synthesis options are changed.
            %.ngc: $(HDL_FILES) $(XST_OPTIONS_FILE)
                    -$(MKDIR) $(PROJNAV_DIR)
                            # The .xst file containing the synthesis options is modified to 
                            # reflect the design name, device, and top-level entity and stored
                            # in a temporary .xst file.
                    $(SET_OPTION_VALUES) $(XST_OPTIONS_FILE) \
                            "set -tmpdir $(PROJNAV_DIR)" \
                            "-lso $(DESIGN_NAME).lso" \
                            "-ifn $(DESIGN_NAME).prj" \
                            "-ofn $(DESIGN_NAME)" \
                            "-p $(PART)" \
                            "-top $(TOP_NAME)" \
                                    > $(PROJNAV_DIR)/tmp.xst
                    xst $(XST_FLAGS) -ifn $(PROJNAV_DIR)/tmp.xst -ofn $*.syr

            # Take the output of the synthesizer and create the NGD file.  This rule
            # will also be triggered if constraints file is changed.
            %.ngd: %.ngc %.ucf
                    ngdbuild $(NGDBUILD_FLAGS) -p $(PART) $*.ngc $*.ngd

            # Map the NGD file and physical-constraints to the FPGA to create the mapped NCD file.
            %_map.ncd %.pcf: %.ngd
                    map $(MAP_FLAGS) -p $(PART) -o $*_map.ncd $*.ngd $*.pcf

            # Place & route the mapped NCD file to create the final NCD file.
            %.ncd: %_map.ncd %.pcf
                    par $(PAR_FLAGS) $*_map.ncd $*.ncd $*.pcf

            # Take the final NCD file and create an FPGA bitstream file.  This rule will also be
            # triggered if the bit generation options file is changed.
            %.bit: %.ncd $(BITGEN_OPTIONS_FILE)
                    bitgen $(BITGEN_FLAGS) -f $(BITGEN_OPTIONS_FILE) $*.ncd

            # Convert a bitstream file into an MCS hex file that can be stored into Flash memory.
            %.mcs: %.bit
                    promgen $(PROMGEN_FLAGS) $*.bit -p mcs

            # Convert a bitstream file into an EXO hex file that can be stored into Flash memory.
            %.exo: %.bit
                    promgen $(PROMGEN_FLAGS) $*.bit -p exo

            # Fit the NGD file synthesized for the CPLD to create the VM6 file.
            %.vm6: %.ngd
                    cpldfit $(CPLDFIT_FLAGS) -p $(PART) $*.ngd

            # Convert the VM6 file into a JED file for the CPLD.
            %.jed: %.vm6
                    hprep6 $(HPREP6_FLAGS) -i $*.vm6

            # Convert JED file into an SVF file for the CPLD.
            %.svf: %.jed $(IMPACT_OPTIONS_FILE)
                    $(SET_OPTION_VALUES) $(IMPACT_OPTIONS_FILE) \
                            "setCable -port svf -file \"$*.svf\"" \
                            "addDevice -position 1 -file \"$*.jed\"" \
                                    > impactcmd.txt
                    $(ECHO) "quit" >> impactcmd.txt
                    impact -batch impactcmd.txt

            # Use .config suffix to trigger creation of a bit/svf file
            # depending upon whether an FPGA/CPLD is the target device.
            %.config: $(if $(IS_CPLD),%.svf,%.bit) ;

            # Create the FPGA timing report after place & route.
            %.twr: %.ncd %.pcf
                    trce $(TRCE_FLAGS) $*.ncd -o $*.twr $*.pcf

            # Use .timing suffix to trigger timing report creation.
            %.timing: %.twr ;

            # Preserve intermediate files.
            .PRECIOUS: %.ngc %.ngd %_map.ncd %.ncd %.twr %.vm6 %.jed

            # Clean up after creating the configuration file.
            %.clean:
                    -$(RM) $*.stx $*.ucf.untf $*.mrp $*.nc1 $*.ngm $*.prm $*.lfp
                    -$(RM) $*.placed_ncd_tracker $*.routed_ncd_tracker
                    -$(RM) $*.pad_txt $*.twx *.log *.vhd~ $*.dhp $*.jhd $*.cel
                    -$(RM) $*.ngr $*.ngc $*.ngd $*.syr $*.bld $*.pcf
                    -$(RM) $*_map.mrp $*_map.ncd $*_map.ngm $*.ncd $*.pad
                    -$(RM) $*.par $*.xpi $*_pad.csv $*_pad.txt $*.drc $*.bgn
                    -$(RM) $*.xml $*_build.xml $*.rpt $*.gyd $*.mfd $*.pnx
                    -$(RM) $*.vm6 $*.jed $*.err $*.ER result.txt tmperr.err *.bak *.vhd~
                    -$(RM) impactcmd.txt
                    -$(RMDIR) xst _ngo $*_html __projnav

            # Clean for distribution.
            %.distclean: %.clean
                    -$(RM) $*.twr

            # Clean everything.
            %.maintainer-clean: %.distclean
                    -$(RM) $*.bit $*.svf $*.exo $*.mcs

            #
            # Default targets for FPGA/CPLD compilations.
            #

            config          : $(DESIGN_NAME).config
            bit             : $(DESIGN_NAME).bit
            svf             : $(DESIGN_NAME).svf
            mcs             : $(DESIGN_NAME).mcs
            exo             : $(DESIGN_NAME).exo
            timing          : $(DESIGN_NAME).timing
            clean           : $(DESIGN_NAME).clean
            distclean       : $(DESIGN_NAME).distclean
            maintainer-clean: $(DESIGN_NAME).maintainer-clean
            nice            : $(subst .vhd,.nice,$(HDL_FILES))

   get_option_values.pl Perl Script
      #
      # Get selected option value from an options file of a Xilinx WebPACK/ISE project
      #
      $option_file = shift @ARGV;         # first argument is the option file name
      open(FILE,$option_file) || die $!;
      $option_name = $ARGV[0];            # second argument is the option name to search for

      # read lines from option file looking for the given option name
      while(<FILE>) {
        chop;
        /^$option_name\s+/ && print $';   # print out the value for the given option
      }

   set_option_values.pl Perl Script
      #
      # Set option values in an options file of a Xilinx WebPACK/ISE project
      #
      $option_file = shift @ARGV;    # first argument is the option file name
      open(FILE,$option_file) || die $!;
      @options = <FILE>;             # read in all the options
      $options = join("",@options);  # join all options into one big string

      # remaining arguments are new option strings that will replace existing options
      foreach (@ARGV) {
        @option_fields = split(/\s+/,$_);  # split new option string into fields
        $option_value = pop @option_fields; # new option value is last field in the string
        $option_name = join(" ",@option_fields);  # option name is all the preceding fields
        $options =~ s/$option_name\s+.*/$option_name $option_value/gi;  # replace existing value with new value
      }

      print $options;  # print the updated option file

   get_project_files.pl Perl Script
      #
      # Output a list of the files found in the .prj file of a Xilinx WebPACK/ISE project
      #
      open(PRJFILE,$ARGV[0]) || die $!;
      while(<PRJFILE>) {
        @fields = split(/\s+/,$_);
        $f = pop(@fields);  # file name is last field of each line
        $f =~ s/\"//g;  # remove any quotations around file names
        print " " . $f;
      }

  Project Makefile
    The contents of the makefile file in the WebPACK/ISE project directory
    can be as simple as:

            # include the rules to build the Xilinx configuration bitstream, etc.
            include xilinx_rules.mk

    You can also override variables in the xilinx_rules.mk file to change
    the behavior of the build process. For example, to target a different
    FPGA, you might use:

            PART = xc2s100-5-tq144

            # include the rules to build the Xilinx configuration bitstream, etc.
            include xilinx_rules.mk

    Or if you don't want to use a constraint file, just give it an empty
    value like so:

            PART = xc2s100-5-tq144
            UCF_FILE =

            # include the rules to build the Xilinx configuration bitstream, etc.
            include xilinx_rules.mk

    To build the FPGA or CPLD configuration bitstream, just type the
    command:

            make

    or:

            make config

    To generate the timing report for an FPGA design, use the command:

            make timing

    To clean any temporary files created during the build process, use the
    command:

            make clean

    You can also remove more of the intermediate files with the command:

            make distclean

    And you can remove all of the above plus the configuration bitstream
    file with:

            make maintainer-clean

  Directory Makefile
    If you have a directory that contains several subdirectories, each of
    which contains a WebPACK/ISE project, then the following makefile will
    build the bitstream for each project. This makefile resides in the
    top-level directory and it activates the makefiles in each project
    subdirectory.

            projects := project1 project2 project3

            # These are the standard targets for creating the configuration bitstream and
            # timing report and also for cleaning each project.
            config          : $(projects:=.config)
            timing          : $(projects:=.timing)
            clean           : $(projects:=.clean)
            distclean       : $(projects:=.distclean)
            maintainer-clean: $(projects:=.maintainer-clean)

            # This rule causes make to enter each project directory and activate
            # the makefile found there in order to create the configuration bitstream.
            $(projects:=.config):
                    $(MAKE) -C $(subst .config,,$@) $@

            # This rule causes make to enter each FPGA project directory and generate
            # a timing report.
            $(projects:=.timing):
                    $(MAKE) -C $(subst .timing,,$@) $@

            # The next three rules cause make to enter each project directory
            # and clean the project to the selected level of cleanliness.

            $(projects:=.clean):
                    $(MAKE) -C $(subst .clean,,$@) $@

            $(projects:=.distclean):
                    $(MAKE) -C $(subst .distclean,,$@) $@

            $(projects:=.maintainer-clean):
                    $(MAKE) -C $(subst .maintainer-clean,,$@) $@

    The following makefile is similar to the previous one but it also allows
    you to retarget the projects at a different type of FPGA or CPLD and use
    new options for the tools.

            # Override the part id for the following projects
            FPGA_PART     := xc3s1000-4-ft256
            fpga_projects := project1 project2

            # Override the part id for the following projects
            CPLD_PART     := xc9572xl-10-vq64
            cpld_projects := project3 project4

            # Override the variables that contain the location of the option files for the
            # synthesizer and bitstream generators so all the projects will be controlled
            # by these master option files in the top-level directory.
            export XST_CPLD_OPTIONS_FILE ?= $(CURDIR)/xst_cpld_options.xst
            export XST_FPGA_OPTIONS_FILE ?= $(CURDIR)/xst_fpga_options.xst
            export BITGEN_OPTIONS_FILE   ?= $(CURDIR)/bitgen_options.ut
            export IMPACT_OPTIONS_FILE   ?= $(CURDIR)/impact_options.txt

            # These are the standard targets for creating the configuration bitstream and
            # timing report and also for cleaning each project.
            config          : $(fpga_projects:=.config)           $(cpld_projects:=.config)
            timing          : $(fpga_projects:=.timing)
            clean           : $(fpga_projects:=.clean)            $(cpld_projects:=.clean)
            distclean       : $(fpga_projects:=.distclean)        $(cpld_projects:=.distclean)
            maintainer-clean: $(fpga_projects:=.maintainer-clean) $(cpld_projects:=.maintainer-clean)

            # This rule causes make to enter each FPGA project directory and activate
            # the makefile found there in order to create the configuration bitstream.
            # Note that the value in the FPGA_PART variable will override the value of the
            # PART variable found in each project directory. 
            $(fpga_projects:=.config):
                    $(MAKE) -C $(subst .config,,$@) PART=$(FPGA_PART) $@

            # This rule causes make to enter each CPLD project directory and activate
            # the makefile found there in order to create the configuration bitstream.
            # Note that the value in the CPLD_PART variable will override the value of the
            # PART variable found in each project directory. 
            $(cpld_projects:=.config):
                    $(MAKE) -C $(subst .config,,$@) PART=$(CPLD_PART) $@

            # This rule causes make to enter each FPGA project directory and generate
            # a timing report.  CPLD projects do not have a separate phase for creating
            # timing reports.
            $(fpga_projects:=.timing):
                    $(MAKE) -C $(subst .timing,,$@) PART=$(FPGA_PART) $@

            # The next three rules cause make to enter each FPGA and CPLD project directory
            # and clean the project to the selected level of cleanliness.

            $(fpga_projects:=.clean) $(cpld_projects:=.clean):
                    $(MAKE) -C $(subst .clean,,$@) $@

            $(fpga_projects:=.distclean) $(cpld_projects:=.distclean):
                    $(MAKE) -C $(subst .distclean,,$@) $@

            $(fpga_projects:=.maintainer-clean) $(cpld_projects:=.maintainer-clean):
                    $(MAKE) -C $(subst .maintainer-clean,,$@) $@

    To build the FPGA and CPLD configuration bitstreams for all the
    projects, just type the command:

            make

    or:

            make config

    To generate the timing reports for all the FPGA designs, use the
    command:

            make timing

    To clean all the project subdirectories, use one of the commands:

            make clean
            make distclean
            make maintainer-clean

  Environment
    These makefiles were developed and tested using the following versions
    of software:

            GNU make          : 3.79.1 (version 3.77.1 does not work)
            Active State perl : 5.8.4, 5.8.8
            Xilinx WebPACK    : 6.3.03i, 8.1.03i

  Source Files
    You can download an example of a Xilinx project directory that uses
    these makefiles and perl scripts from
    http://www.xess.com/projects/XILINX_MAKEFILES.tar.gz .

  Author
    Dave Vanden Bout, X Engineering Software Systems Corp.

    Send bug reports to bugs@xess.com.

  Copyright and License
    � 2005-2006 by X Engineering Software Systems Corporation.

    These applications can be freely distributed and modified as long as you
    do not remove the attributions to the author or his employer.

  History
    *   03/26/2007 - Modified xilinx_rules.mk to support ISE9 project
        directory structure.

    *   05/16/2006 - Added 'nice' feature to prettify VHDL source files.

    *   05/16/2006 - Fixed get_project_files.pl to handle quotes in Xilinx
        ISE 8.1i .prj file.

    *   05/05/2005 - Initial release.

