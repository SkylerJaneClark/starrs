<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**
 * Library of general functions for the operation of IMPULSE
 */
class Impulselib {

	private $fname;
	private $lname;
	private $uname;
	private $CI;

    /**
     * Constructor. This will load in your identification information for use in privilege leveling
     */
	function __construct() {
		$CI =& get_instance();
		
	}

	public function test() {
		echo "Hi";
		die;
	}

    /**
     * Get a standard IPv6 autoconf address from your MAC address
     * @param $mac  The MAC address of the interface
     * @return string
     */
	function get_eui64_address($mac) {
		return $mac;
	}

    /**
     * Get the path of the OS image based on the OS name
     * @param $osname   The name of the OS to get
     * @return
     */
	function get_os_img_path($osname) {
		$paths['Cisco IOS'] = "/media/images/os/CiscoIOS.png";
		$paths['Windows XP'] = "/media/images/os/WindowsXP.png";
		$paths['Windows Vista'] = "/media/images/os/WindowsVista.png";
		$paths['Windows 7'] = "/media/images/os/Windows7.png";
		$paths['Windows Server 2003'] = "/media/images/os/WindowsServer2003.png";
		$paths['Windows Server 2008'] = "/media/images/os/WindowsServer2008.png";
		$paths['Windows Server 2008 R2'] = "/media/images/os/WindowsServer2008R2.png";
		$paths['Gentoo'] = "/media/images/os/Gentoo.png";
		$paths['Ubuntu'] = "/media/images/os/Ubuntu.png";
		$paths['Fedora'] = "/media/images/os/Fedora.png";
		$paths['CentOS'] = "/media/images/os/CentOS.png";
		$paths['Slackware'] = "/media/images/os/Slackware.png";
		$paths['Arch'] = "/media/images/os/Arch.png";
		$paths['Exherbo'] = "/media/images/os/Exherbo.png";
		$paths['Debian'] = "/media/images/os/Debian.png";
		$paths['FreeBSD'] = "/media/images/os/FreeBSD.png";
		$paths['OpenBSD'] = "/media/images/os/OpenBSD.png";
		$paths['NetBSD'] = "/media/images/os/NetBSD.png";
		$paths['DragonflyBSD'] = "/media/images/os/DragonflyBSD.png";
		$paths['ClockyOS'] = "/media/images/os/ClockyOS.png";
		$paths['Xbox'] = "/media/images/os/Xbox.png";
		$paths['Playstation'] = "/media/images/os/Playstation.png";
		$paths['Wii'] = "/media/images/os/Wii.png";
		$paths['Cisco CatOS'] = "/media/images/os/CiscoCatOS.png";
		$paths['Mac OS X'] = "/media/images/os/MacOSX.png";
		$paths['Solaris'] = "/media/images/os/Solaris.png";
		$paths['openSuSE'] = "/media/images/os/openSuSE.png";
		$paths['Red Hat Enterprise Linux'] = "/media/images/os/RedHatEnterpriseLinux.png";
		$paths['VMware ESX'] = "/media/images/os/VMwareESX.png";
		$paths['ChromeOS'] = "/media/images/os/ChromeOS.png";
		$paths['OpenWRT'] = "/media/images/os/OpenWRT.png";
		$paths['Vyatta'] = "/media/images/os/Vyatta.png";
		$paths['Android'] = "/media/images/os/Android.png";

		return $paths[$osname];
	}

    /**
     * Clean up a URL that has spaces in it to have %20's
     * @param $url  The URL to parse
     * @return string
     */
	public function remove_url_space($url) {
		return preg_replace("/%20/"," ",$url);
	}



    /**
     * Get the object of the current active system from $_SESSION
     * @return System
     */
	public function get_active_system() {
        // Check if the session was started
		if(session_id() == "") { 
			session_start();
		}

        // I have no idea why this works.
        require_once(APPPATH . "controllers/systems.php");
        if(!isset($_SESSION['activeSystem'])) {
            throw new ObjectNotFoundException("Could not find your system. Make sure you aren't pulling any URL shenanigans. Otherwise, click Systems on the left and start again.");
        }
		return unserialize($_SESSION['activeSystem']);
	}

    /**
     * Set the active system in $_SESSION
     * @param $sys  The system to set to
     * @return void
     */
	public function set_active_system($sys) {
        // Check if the session was started
		if(session_id() == "") { 
			session_start();
		}

        // Set it up!
		$_SESSION['activeSystem'] = serialize($sys);
	}

    /**
     * Clean up Postgres's extreme timestamp to only have what we want
     * @param $timestamp    The timestamp string to parse
     * @return string
     */
	public function clean_timestamp($timestamp) { 
		return preg_replace('/:(\d+).(\d+)$/','',$timestamp); 
	}
	
}

/* End of file Impulselib.php */
/* Location: ./application/libraries/Impulselib.php */
