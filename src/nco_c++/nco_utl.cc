// $Header: /data/zender/nco_20150216/nco/src/nco_c++/nco_utl.cc,v 1.15 2006-05-16 22:27:09 zender Exp $ 

// Implementation (declaration) of C++ interface utilities for netCDF routines

/* Copyright (C) 2001--2005 Charlie Zender
   This software may be modified and/or re-distributed under the terms of the GNU General Public License (GPL) Version 2
   See http://www.gnu.ai.mit.edu/copyleft/gpl.html for full license text */

#include <nco_utl.hh> // C++ interface utilities for netCDF routines

// netCDF classes

// Friendly functions begin

// Friendly functions end
// Static members begin
//const int NCO_NOERR=NC_NOERR; // [enm] Variable'ize CPP macro for use in function parameter initialization
// Static members end
// Static member functions begin

// Static member functions end
// Public member functions begin

// Public member functions end
// Private member functions begin

// Private member functions end
// Global functions with C++ linkages begin

void 
nco_err_exit // [fnc] Lookup, print netCDF error message, exit
(const int &rcd, // I [enm] netCDF error code
 const std::string &msg, // I [sng] Supplemental error message
 const std::string &msg_opt) // I [sng] Optional supplemental error message
{
  /* Purpose: Print netCDF error message, routine name, and exit 
     Routine is called by all wrappers when fatal error is encountered
     msg variable allows wrapper to pass more descriptive information than 
     netCDF-defined error message contains.
     Use msg to print, e.g., name of variable which caused error */
  const std::string sbr_nm("nco_err_exit()");
  if(rcd != NC_NOERR){
    std::cout << sbr_nm << ": ERROR netCDF library returned error code " << rcd << std::endl;
    std::cout << sbr_nm << ": ERROR " << msg << std::endl << nc_strerror(rcd) << std::endl;
    if(msg_opt != "") std::cout << sbr_nm << ": " << msg_opt << std::endl;
#ifdef ABORT_ON_ERROR
    std::abort(); // [fnc] Produce core dump
#else // !ABORT_ON_ERROR
#ifndef SGIMP64 // fxm: SGI IRIX CC does not support std::exit nor have cstdlib
    std::exit(EXIT_FAILURE); // [fnc] Exit nicely
#else // SGIMP64
    exit(EXIT_FAILURE); // [fnc] Exit nicely
#endif // SGIMP64
#endif // !ABORT_ON_ERROR
  } // endif error
} // end nco_err_exit()

void 
nco_wrn_prn // [fnc] Print NCO warning message and return
(const std::string &msg, // I [sng] Supplemental warning message
 const std::string &msg_opt) // I [sng] Optional supplemental warning message
{
  /* Purpose: Print NCO warning message and return
     Routine is called by some wrappers when non-fatal weirdness is encountered
     msg variable allows wrapper to pass descriptive information
     Use msg to print, e.g., name of variable which caused warning */
  const std::string sbr_nm("nco_wrn_prn()");
  std::cout << sbr_nm << ": WARNING " << msg << std::endl;
  if(msg_opt != "") std::cout << sbr_nm << ": " << msg_opt << std::endl;
  return;
} // end nco_wrn_prn()

// Begin nco_inq_varsz() overloads

int // O [enm] Return success code
nco_inq_varsz // [fnc] Compute size of variable
(const int &nc_id, // I [enm] netCDF file ID
 const int &var_id, // I [id] Variable ID
 size_t &var_sz) // O [nbr] Variable size
{
  // Purpose: Compute size (number of elements) in specified variable
  int dmn_nbr; // [nbr] Number of dimensions
  //  int dmn_id[NC_MAX_DIMS]; // [id] Dimension IDs
  size_t dmn_sz; // [nbr] Dimension size
  int rcd=nco_inq_varndims(nc_id,var_id,dmn_nbr);
  int *dmn_id=new int[dmn_nbr]; // [id] Dimension IDs
  rcd=nco_inq_vardimid(nc_id,var_id,dmn_id);
  // Initialize variable size
  var_sz=1; // [nbr] Variable size
  for(int dmn_idx=0;dmn_idx<dmn_nbr;dmn_idx++){
    rcd=nco_inq_dimlen(nc_id,dmn_id[dmn_idx],dmn_sz);
    var_sz*=dmn_sz; // [nbr] Variable size
  } // end loop over dmn
  delete []dmn_id; // [id] Dimension IDs
  return rcd;
} // end nco_inq_varsz()

size_t // O [nbr] Variable size
nco_inq_varsz // [fnc] Compute size of variable
(const int &nc_id, // I [enm] netCDF file ID
 const int &var_id) // I [id] Variable ID
{
  // Purpose: Compute size (number of elements) in specified variable
  size_t var_sz; // O [nbr] Variable size
  int rcd=nco_inq_varsz(nc_id,var_id,var_sz);
  rcd+=0; /* CEWI */
  return var_sz;
} // end nco_inq_varsz()

// End nco_inq_varsz() overloads

int // O [enm] Return success code
nco_inq_varsrt // [fnc] Inquire variable dimension IDS
(const int &nc_id, // I [enm] netCDF file ID
 const int &var_id, // I [id] Variable ID
 std::valarray<size_t> &srt, // O [idx] Starting indices
 const int &rcd_opt) // I [enm] Optional non-fatal return code 
{
  // Purpose: Return valarray of default starting indices
  int dmn_nbr; // I [nbr] Number of dimensions
  int rcd=nco_inq_varndims(nc_id,var_id,dmn_nbr,rcd_opt);
  srt.resize(dmn_nbr);
  srt=1;
  return rcd;
} // end nco_inq_varsrt() 

int // [nbr] Internal (native) size (Bytes) of netCDF external type
nco_typ_lng // [fnc] Internal (native) size (Bytes) of netCDF external type
(const nc_type &nco_typ) // I [enm] netCDF external type
{ 
  /* Purpose: Return native size of specified netCDF type
     Routine is used to determine memory required to store variables in RAM */
  switch(nco_typ){ 
  case NC_FLOAT: 
    return sizeof(float); 
  case NC_DOUBLE: 
    return sizeof(double); 
  case NC_INT: 
    return sizeof(long); 
  case NC_SHORT: 
    return sizeof(short); 
  case NC_CHAR: 
    return sizeof(unsigned char); 
  case NC_BYTE: 
    return sizeof(signed char); 
  default: nco_dfl_case_nctype_err(); break;
  } // end switch
  // Some C compilers, e.g., SGI cc, need a return statement at the end of non-void functions
  return (int)-1;
} // end nco_typ_lng()

std::string // O [sng] String version of netCDF external type enum
nco_typ_sng // [fnc] String version of netCDF external type enum
(const nc_type &nco_typ) // I [enm] netCDF external type
{
  switch(nco_typ){
  case NC_FLOAT:
    return "NC_FLOAT";
  case NC_DOUBLE:
    return "NC_DOUBLE";
  case NC_INT:
    return "NC_INT";
  case NC_SHORT:
    return "NC_SHORT";
  case NC_CHAR:
    return "NC_CHAR";
  case NC_BYTE:
    return "NC_BYTE";
  default: nco_dfl_case_nctype_err(); break;
  } // end switch
  // Some C compilers, e.g., SGI cc, need a return statement at the end of non-void functions
  return static_cast<std::string>("");
} /* end nco_typ_sng() */

std::string // O [sng] String version of C++ internal type for storing netCDF external type enum
nco_c_typ_sng // [fnc] String version of C++ internal type for storing netCDF external type enum
(const nc_type &nco_typ) // I [enm] netCDF external type
{
  /* Purpose: Divine internal (native) C type string from netCDF external type enum
     fxm: This breaks on Crays where both NC_FLOAT and NC_DOUBLE are native type float */
  switch(nco_typ){
  case NC_FLOAT:
    return "float";
  case NC_DOUBLE:
    return "double";
  case NC_INT:
    return "long";
  case NC_SHORT:
    return "short";
  case NC_CHAR:
    return "unsigned char";
  case NC_BYTE:
    return "signed char";
  default: nco_dfl_case_nctype_err(); break;
  } // end switch
  // Some C compilers, e.g., SGI cc, need a return statement at the end of non-void functions
  return static_cast<std::string>("");
} // end nco_c_typ_sng()

std::string // O [sng] String version of C++ internal type for storing netCDF external type enum
nco_ftn_typ_sng // [fnc] String version of C++ internal type for storing netCDF external type enum
(const nc_type &nco_typ) // I [enm] netCDF external type
{
  /* Purpose: Divine internal (native) Fortran type string from netCDF external type enum
     fxm: This breaks on Crays where both NC_FLOAT and NC_DOUBLE are native type real */
  switch(nco_typ){
  case NC_FLOAT:
    return "real";
  case NC_DOUBLE:
    return "double precision";
  case NC_INT:
    return "integer";
  case NC_SHORT:
    return "integer*2";
  case NC_CHAR:
    return "character";
  case NC_BYTE:
    return "char";
  default: nco_dfl_case_nctype_err(); break;
  } /* end switch */
  // Some C compilers, e.g., SGI cc, need a return statement at the end of non-void functions
  return static_cast<std::string>("");
} // end nco_ftn_typ_sng()

void 
nco_dfl_case_nctype_err(void) // [fnc] Handle illegal nc_type references
{
  /* Purpose: Convenience routine for printing error and exiting when
     switch(nctype) statement receives an illegal default case
     NCO emits warnings when compiled by GCC with -DNETCDF2_ONLY since, 
     apparently, there are a whole bunch of things besides numeric
     types in the old nctype enum and gcc warns about enums that are
     not exhaustively considered in switch() statements. 
     All these default statements can be removed with netCDF3 interface
     so perhaps these should be surrounded with #ifdef NETCDF2_ONLY
     constructs, but they actually do make sense for netCDF3 as well
     so I have implemented a uniform error function, nco_dfl_case_nctype_err(), 
     to be called by all routines which emit errors only when compiled with
     NETCDF2_ONLY.
     This makes the behavior easy to modify or remove in the future.

     Placing this in its own routine also has the virtue of saving many lines 
     of code since this function is used in many many switch() statements. */
  const std::string sbr_nm("nco_dfl_case_nctype_err()");
  std::cout << sbr_nm << ": ERROR switch(nctype) statement fell through to default case, which is illegal.\nNot handling the default case causes gcc to emit warnings when compiling NCO with the NETCDF2_ONLY token (because nctype defintion is braindead in netCDF2). Exiting..." << std::endl;
#ifdef ABORT_ON_ERROR
  std::abort(); // [fnc] Produce core dump
#else
#ifndef SGIMP64 // fxm: SGI IRIX CC does not support std::exit nor have cstdlib
    std::exit(EXIT_FAILURE); // [fnc] Exit nicely
#else // SGIMP64
    exit(EXIT_FAILURE); // [fnc] Exit nicely
#endif // SGIMP64
#endif // !ABORT_ON_ERROR

} // end nco_dfl_case_nctype_err()

// Begin nco_get_xtype() overloads

nc_type // O [enm] External netCDF type
nco_get_xtype // [fnc] Determine external netCDF type
(const float &var_val) // I [frc] Variable value
{
  /* Purpose: Return "best" netCDF external type for argument
     Algorithm assumes internal representation is IEEE
     Thus algorithm fails for Crays, where native float is 8 B (double precision) */
  float flt_foo=var_val; // CEWI
  flt_foo++; // Squelch "declared but never referenced" warnings
  return NC_FLOAT;
} // end nco_get_xtype()

nc_type // O [enm] External netCDF type
nco_get_xtype // [fnc] Determine external netCDF type
(const double &var_val) // I [frc] Variable value
{
  /* Purpose: Return "best" netCDF external type for argument
     Algorithm assumes internal representation is IEEE
     Thus algorithm fails for Crays, where native float is 8 B (double precision) */
  double dbl_foo=var_val; // CEWI
  dbl_foo++; // Squelch "declared but never referenced" warnings
  return NC_DOUBLE;
} // end nco_get_xtype()

// End nco_get_xtype() overloads

// Global functions with C++ linkages end
