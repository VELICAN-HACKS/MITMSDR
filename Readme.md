# There mainly three things here:
 1. MITMSDR 
 2. spectrum
 3. Manual reverse shell
  

  1. MITMSDR
     Installation
     Clone the project and run the setup file:

     ./setup

     One of the MITM Plugins relies on peinjector service, this has to be installed manually following the instructions of the project.

     https://github.com/JonDoNym/peinjector

     Usage
     First enter the FDL Console interface as root:

     ./fdlconsole

     For now there only is a console interface that is very easy to use and has tab completion! The whole thing will work according to the fdl.conf file. You can view and change all configurations via de console, just type: config <press double tab> to list the modules available for configuration. While working on the console type: listargs to view the available parameters (here you can check if configurations are OK), then type:

     set <parameter> <value> to change it. If a parameter is (dict) it means it is another configurable module within.

     To start an access point make sure you have it configured correctly, type: config airhost
     check if everything is OK (use listargs)
     config aplauncher check if everything is OK (use listargs)
     config dnsmasqhandler

     check if everything is OK and start the access point

     start airhost
     You can also configure an access point by copying one that is nearby. Start scanning:
     config airscanner
     check if everything is OK (use listargs)
     start airscanner ... wait ...

     show sniffed_aps

      This lists the sniffed access points with their ids

     copy ap <id> OR show sniffed_probes copy probe <id> Then start the fake access point

     start airhost
     You can deauthenticate others from their network while running the acces point. To add access points or clients to be deauthenticated type: show sniffed_aps
     add aps <filter_string>

     The filter_string follows an easy syntax, it goes: <filter_keyword> <filter_args>

     The args can be any of the column names listed in the table. The filter keywords are 'where' for inclusive filtering or 'only' for exclusive filtering, examples: This will add the access point whose id is 5 to the deauthentication list (this is adding a single and specific AP): add aps where id = 5
     This will add the access point whose ssid is 'StarbucksWifi' to the deauthentication list:  add aps where ssid = StarbucksWifi
     This will add the access point whose encryption type has 'wpa' OR 'opn' to the deauthentication list: add aps where crypto = wpa, crypto = opn
     This will add the access point whose ssid id 'freewifi' AND is on channel 6 to the deauthentication list: add aps only ssid = freewifi, channel = 6
     You can use the same interface for injecting packets while running the fake access point. You can check and set configurations with:
     config airinjector listargs

After all that run the Injector (which by default performs Deauthentication attack):

start airinjector

Same can be done when deleting from the deauth list with the 'del' command. The 'show' command can also be followed by a filter string

Contributors can program Plugins in python either for the airscanner or airhost or airdeauthor. Contributors can also code MITM scripts for mitmproxy.

2. spectrum 
   
   cd spectrum
   chmod +x ./spectrum
   gem install colorize

   cp ./spectrum /usr/local/bin/  # optional
   Usage:
   ./spectrum   #  or simply `spectrum` if you copied it to /usr/local/bin
    This will spawn an interactive shell, along with inspectrum itself. As you usually would, open your capture file. Then align the cursors, right click the signal, add amplitued plot (for OOK) or add frequency plot (for 2FSK). Right click the plot that appeared, and click extract data. The demodulated bits should appear in your terminal.

     This script has been tested with OOK & 2FSK signals with a 100% success rate (so far...). It does some sanity checking and will alert if you something doesn't feel right.

    You can also use this tool to compare 2 parts of a signal in the same file, or signals from two separate files.

 3. Manual python reverse shell #optional   