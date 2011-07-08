<?php
/*
 * This class contains the definition of an IMPULSE Object. Basically any true 
 * object in the Impulse system has a date modified, created, and a user who
 * performed the last modification. This class provides simple inheritance to
 * access all that data. 
 */

abstract class ImpulseObject {
	////////////////////////////////////////////////////////////////////////
	// CI OUTSIDE WORLD
	
	// World
	protected $CI;
	
	////////////////////////////////////////////////////////////////////////
	// MEMBER VARIABLES
	
	// long		The date the object was created (in the system), stored as a
	// Unix timestamp 
	private $dateCreated;
	
	// long		The date the object was last modified in the system, stored as
	// a Unix timestamp
	private $dateModified;
	
	// string	The last user to modify the the object, can be used as a FK
	// for user lookups 
	private $lastModifier;
	
	////////////////////////////////////////////////////////////////////////
	// CONSTRUCTOR
	/**
	 * Constructs a new ImpulseObject using the provided values
	 * @param	long	$dateCreated	The timestamp the object was created
	 * @param 	long	$dateModified	The timestamp the object was modified
	 * @param 	string	$lastModifier	The last user to modify the object
	 */
	public function __construct($dateCreated, $dateModified, $lastModifier) {
		// Store the data in the member variables
		$this->dateCreated  = $dateCreated;
		$this->dateModified = $dateModified;
		$this->lastModifier = $lastModifier;
		$this->CI			=& get_instance();
	}
	
	////////////////////////////////////////////////////////////////////////
	// GETTERS
	/**
	 * These are all prety simple. They return the variable in the name
	 */
	public function get_date_created()  { return $this->dateCreated; }
	public function get_date_modified() { return $this->dateModified; }
	public function get_last_modifier() { return $this->lastModifier; }
}