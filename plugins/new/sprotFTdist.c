/************************************************************************/
/**

   Program:    sprotFTdist
   \file       sprotFTdist.c
   
   \version    V1.0
   \date       01.02.22
   \brief         
   
   \copyright  (c) UCL / Prof. Andrew C. R. Martin 2022
   \author     Prof. Andrew C. R. Martin
   \par
               Institute of Structural & Molecular Biology,
               University College,
               Gower Street,
               London.
               WC1E 6BT.
   \par
               andrew@bioinf.org.uk
               andrew.martin@ucl.ac.uk
               
**************************************************************************

   This program is not in the public domain, but it may be copied
   according to the conditions laid out in the accompanying file
   COPYING.DOC

   The code may be modified as required, but any modifications must be
   documented so that the person responsible can be identified.

   The code may not be sold commercially or included as part of a 
   commercial product except as described in the file COPYING.DOC.

**************************************************************************

   Description:
   ============

**************************************************************************

   Usage:
   ======

**************************************************************************

   Revision History:
   =================
   V1.0   01.02.22   Original   By: ACRM

*************************************************************************/
/* Debugging
*/
/* #define PRINTFEATURES 1 */
/* #define SHOWPROGRESS  1 */

/************************************************************************/
/* Includes
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "bioplib/pdb.h"
#include "bioplib/macros.h"
#include "bioplib/MathType.h"

/************************************************************************/
/* Defines and macros
*/
#define MAXLABEL  8
#define SMALLBUFF 16
#define MAXBUFF   256
#define MAXSITE   100
#define BADCUTDIST (REAL)4.0

#ifdef SHOWPROGRESS
#define PROGRESS(t) fprintf(stderr, "*** %s\n", t)
#else
#define PROGRESS(t)
#endif

typedef struct _features
{
   REAL MinDistActSite;
   REAL MinDistBinding;
   REAL MinDistCABinding;
   REAL MinDistDNABinding;
   REAL MinDistNPBinding;
   REAL MinDistMetal;
   REAL MinDistModRes;
   REAL MinDistCarbohyd;
   REAL MinDistMotif;
   REAL MinDistLipid;

   int NActSite;
   int NBinding;
   int NCABinding;
   int NDNABinding;
   int NNPBinding;
   int NMetal;
   int NModRes;
   int NCarbohyd;
   int NMotif;
   int NLipid;

   char ActSite[MAXSITE][MAXLABEL];
   char Binding[MAXSITE][MAXLABEL];
   char CABinding[MAXSITE][MAXLABEL];
   char DNABinding[MAXSITE][MAXLABEL];
   char NPBinding[MAXSITE][MAXLABEL];
   char Metal[MAXSITE][MAXLABEL];
   char ModRes[MAXSITE][MAXLABEL];
   char Carbohyd[MAXSITE][MAXLABEL];
   char Motif[MAXSITE][MAXLABEL];
   char Lipid[MAXSITE][MAXLABEL];
}  FEATURES;

typedef struct _pdbsws
{
   char pdb[SMALLBUFF],
      chain[SMALLBUFF],
      resid[SMALLBUFF],
      pdbaa[SMALLBUFF],
      ac[SMALLBUFF],
      id[SMALLBUFF],
      upcount[SMALLBUFF],
      aa[SMALLBUFF];
   struct _pdbsws *next;
}  PDBSWS;

/************************************************************************/
/* Globals
*/

/************************************************************************/
/* Prototypes
*/

/************************************************************************/
/*

 */


BOOL gVerbose = FALSE;

#define SERVERURL "http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1"
#define UNIPROTURL "https://www.uniprot.org/uniprot/"


/* External prototypes */
struct http_response* http_get(char *url, char *custom_headers);

/* Prototypes */
BOOL ParseCmdLine(int argc, char **argv, char *resid, char *newaa,
                  char *infile);
int main(int argc, char **argv);
void FindPDBCode(char *infile, char *pdbcode);
void FindUniProtCode(char *pdbcode, char *resid, char *uniprotcode);
FEATURES FindFeatures(char *uniprotcode);
void MapFeaturesToPDB(FEATURES *features, char *upcode, char *pdbcode, char *chain);
void MapFeature(char *label, char *upcode, char *pdbcode, char *chain, int nres, char resid[MAXSITE][MAXLABEL]);
void CalculateFeatureDistances(FEATURES *features, char *resid, char *infile);
void Usage(void);
void CopyItem(char *body, char *key, char *dest);
PDBSWS *ParsePDBSWSResponse(char *response);
char *RunExternal(char *cmd);
void SetFeature(char *text, char *feature, int *nfeature, char residues[MAXSITE][MAXLABEL]);
int ExpandRange(char *range, int *residues);
void FindPDBResFromUniProt(char *upcode, char *upresid, char *pdbcode, char *chain, char *resid);
void PopulateFeatureDistance(PDB *pdb, char *chain, int resnum, char *insert,
                             int nRes, char resids[MAXSITE][MAXLABEL], REAL *minDist);
void PrintAResult(char *label, REAL dist);
void PrintResults(FEATURES features);

#ifdef PRINTFEATURES
void PrintAFeature(char *label, int nres, char resids[MAXSITE][MAXLABEL], REAL dist);
void PrintFeatures(FEATURES features);
#endif






/************************************************************************/
/************************************************************************/
int main(int argc, char **argv)
{
   char resid[SMALLBUFF],
        newaa[SMALLBUFF],
      infile[MAXBUFF],
      uniprotcode[SMALLBUFF],
      pdbcode[SMALLBUFF];
   FEATURES features;
   
   
   if(ParseCmdLine(argc, argv, resid, newaa, infile))
   {
      char chain[MAXLABEL],
         insert[MAXLABEL];
      int resnum;
      
      FindPDBCode(infile, pdbcode);
      PROGRESS("Finding UniProt code");
      FindUniProtCode(pdbcode, resid, uniprotcode);
#ifdef DEBUG
      printf("UP: %s\n", uniprotcode);
#endif
      PROGRESS("Finding features");
      features = FindFeatures(uniprotcode);
#ifdef PRINTFEATURES
      PrintFeatures(features);
#endif
      PROGRESS("Mapping features back to PDB");
      blParseResSpec(resid, chain, &resnum, insert);
      MapFeaturesToPDB(&features, uniprotcode, pdbcode, chain);
      PROGRESS("Calculating feature distanced");
      CalculateFeatureDistances(&features, resid, infile);
#ifdef PRINTFEATURES
      PrintFeatures(features);
#endif
      PrintResults(features);
   }
   else
   {
      Usage();
   }
   
   return(0);
}


/************************************************************************/
void MapFeaturesToPDB(FEATURES *features, char *upcode, char *pdbcode, char *chain)
{
   char resid[SMALLBUFF];
   
   MapFeature("Active Site",  upcode, pdbcode, chain, features->NActSite,    features->ActSite);
   MapFeature("Binding",      upcode, pdbcode, chain, features->NBinding,    features->Binding);
   MapFeature("CA Binding",   upcode, pdbcode, chain, features->NCABinding,  features->CABinding);
   MapFeature("DNA Binding",  upcode, pdbcode, chain, features->NDNABinding, features->DNABinding);
   MapFeature("NP Binding",   upcode, pdbcode, chain, features->NNPBinding,  features->NPBinding);
   MapFeature("Metal",        upcode, pdbcode, chain, features->NMetal,      features->Metal);
   MapFeature("ModRes",       upcode, pdbcode, chain, features->NModRes,     features->ModRes);
   MapFeature("Carbohydrate", upcode, pdbcode, chain, features->NCarbohyd,   features->Carbohyd);
   MapFeature("Motif",        upcode, pdbcode, chain, features->NMotif,      features->Motif);
   MapFeature("Lipid",        upcode, pdbcode, chain, features->NLipid,      features->Lipid);
}

/************************************************************************/
void MapFeature(char *label, char *upcode, char *pdbcode, char *chain, int nres, char resid[MAXSITE][MAXLABEL])
{
   int i;

   for(i=0; i<nres; i++)
   {
      FindPDBResFromUniProt(upcode, resid[i], pdbcode, chain, resid[i]);
   }
}


/************************************************************************/
BOOL ParseCmdLine(int argc, char **argv, char *resid, char *newaa,
                  char *infile)
{
   argc--;
   argv++;

   infile[0] = resid[0] = newaa[0] = '\0';
   
   while(argc)
   {
      if(argv[0][0] == '-')
      {
         switch(argv[0][1])
         {
         case 'v':
            gVerbose = TRUE;
            break;
         case 'h':
         default:
            return(FALSE);
            break;
         }
      }
      else
      {
         /* Check that there are only 3 arguments left                  */
         if(argc != 3)
            return(FALSE);
         
         /* Copy the first to infile                                    */
         strcpy(resid, argv[0]);
         /* Copy the first to infile                                    */
         strcpy(newaa, argv[1]);
         /* Copy the first to infile                                    */
         strcpy(infile, argv[2]);
         
         return(TRUE);
      }
      argc--;
      argv++;
   }
   
   return(TRUE);
}


/************************************************************************/
void FindPDBCode(char *infile, char *pdbcode)
{
   strcpy(pdbcode, blFNam2PDB(infile));
}

/************************************************************************/
void FindUniProtCode(char *pdbcode, char *resid, char *uniprotcode)
{
   char chain[MAXLABEL],
      insert[MAXLABEL],
      url[MAXBUFF],
      *result;
   char cmd[MAXBUFF];
   int  resnum;
   PDBSWS *pdbsws = NULL;
   
   blParseResSpec(resid, chain, &resnum, insert);
   sprintf(url, "%s&qtype=pdb&id=%s&chain=%s&res=%d%s", SERVERURL, pdbcode, chain, resnum, insert);
   KILLTRAILSPACES(url);
#ifdef DEBUG
   fprintf(stderr,"URL: %s\n", url);
#endif
   /*
   http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=pdb&id=3u1n&chain=A&res=123
   */
   sprintf(cmd, "/usr/bin/curl -s '%s'", url);
   result = RunExternal(cmd);

   if((pdbsws = ParsePDBSWSResponse(result))!=NULL)
   {
      strcpy(uniprotcode, pdbsws->ac);
      FREELIST(pdbsws, PDBSWS);
   }
   else
   {
      fprintf(stderr, "No data from PDBSWS call: %s\n", url);
      exit(1);
   }
}

/************************************************************************/
void FindPDBResFromUniProt(char *upcode, char *upresid, char *pdbcode, char *chain, char *resid)
{
   char   url[MAXBUFF];
   char cmd[MAXBUFF];
   int    resnum;
   char *result;
   PDBSWS *pdbsws = NULL;
   
   sprintf(url, "%s&qtype=ac&id=%s&res=%s", SERVERURL, upcode, upresid);
   KILLTRAILSPACES(url);
#ifdef DEBUG
   fprintf(stderr,"URL: %s\n", url);
#endif
   /*
   http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=ac&id=Q9Y3Z3&res=137
   */
   sprintf(cmd, "/usr/bin/curl -s '%s'", url);
   result = RunExternal(cmd);

   if((pdbsws=ParsePDBSWSResponse(result))!=NULL)
   {
      PDBSWS *p;
      for(p=pdbsws; p!=NULL; NEXT(p))
      {
         if(!strcmp(pdbcode, p->pdb) &&
            !strcmp(chain,   p->chain))
         {
            strcpy(resid, pdbsws->resid);
            break;
         }
      }
      FREELIST(pdbsws, PDBSWS);
   }
   else
   {
      if(gVerbose)
         fprintf(stderr, "No data from PDBSWS call: %s\n", url);
   }
}

/************************************************************************/
FEATURES FindFeatures(char *uniprotcode)
{
   FEATURES features;
   struct http_response *httpResponse;
   char url[MAXBUFF];
   char cmd[MAXBUFF];
   char *result;

   sprintf(url, "%s%s.txt", UNIPROTURL, uniprotcode);
   sprintf(cmd, "/usr/bin/curl -s '%s'", url);

   result = RunExternal(cmd);

   features.NActSite = 0;
   features.NBinding = 0;
   features.NCABinding = 0;
   features.NDNABinding = 0;
   features.NNPBinding = 0;
   features.NMetal = 0;
   features.NModRes = 0;
   features.NCarbohyd = 0;
   features.NMotif = 0;
   features.NLipid = 0;
   
   features.MinDistActSite = (REAL)-1.0;
   features.MinDistBinding = (REAL)-1.0;
   features.MinDistCABinding = (REAL)-1.0;
   features.MinDistDNABinding = (REAL)-1.0;
   features.MinDistNPBinding = (REAL)-1.0;
   features.MinDistMetal = (REAL)-1.0;
   features.MinDistModRes = (REAL)-1.0;
   features.MinDistCarbohyd = (REAL)-1.0;
   features.MinDistMotif = (REAL)-1.0;
   features.MinDistLipid = (REAL)-1.0;
   
   SetFeature(result, "ACT_SITE", &(features.NActSite),    features.ActSite);
   SetFeature(result, "BINDING",  &(features.NBinding),    features.Binding);
   SetFeature(result, "CA_BIND",  &(features.NCABinding),  features.CABinding);
   SetFeature(result, "DNA_BIND", &(features.NDNABinding), features.DNABinding);
   SetFeature(result, "NP_BIND",  &(features.NNPBinding),  features.NPBinding);
   SetFeature(result, "METAL",    &(features.NMetal),      features.Metal);
   SetFeature(result, "MOD_RES",  &(features.NModRes),     features.ModRes);
   SetFeature(result, "CARBOHYD", &(features.NCarbohyd),   features.Carbohyd);
   SetFeature(result, "MOTIF",    &(features.NMotif),      features.Motif);
   SetFeature(result, "LIPID",    &(features.NLipid),      features.Lipid);
   
   return(features);
}

/************************************************************************/
void SetFeature(char *text, char *feature, int *nFtResidues, char ftResidues[MAXSITE][MAXLABEL])
{
   static char *buffer = NULL;
   char *cstart, *cstop;
   char key[MAXBUFF];

   if(buffer==NULL)
   {
      if((buffer = (char *)malloc((strlen(text)+2)*sizeof(char)))==NULL)
      {
         fprintf(stderr, "No memory for buffer\n");
         exit(1);
      }
   }
   strcpy(buffer, text);

   PROGRESS(feature);
   
   sprintf(key, "FT   %s", feature);

   cstart=cstop=buffer;
   while((cstart!=NULL) && (cstop!=NULL) && (*cstart != '\0'))
   {
      if((cstop = strchr(cstart, '\n'))!=NULL)
      {
         *cstop = '\0';
      }

#ifdef DEBUG
      if(strstr(key, "MOD_RES"))
      {
         
         if(!strncmp(cstart, "FT ", 3) && strstr(cstart, "MOD_RES"))
         {
            fprintf(stderr, "%s\n", cstart);
         }
      }
#endif
      
      
      if(!strncmp(cstart, key, strlen(key)))
      {
         int residues[MAXSITE];
         int nInRange;
         int i;
            
         nInRange = ExpandRange(cstart, residues);
         for(i=0; i<nInRange; i++)
         {
            char resid[MAXLABEL];
            sprintf(resid, "%d", residues[i]);
            strcpy(ftResidues[*nFtResidues], resid);
            (*nFtResidues)++;
         }
#ifdef DEBUG
         fprintf(stderr, "%s\n", cstart);
#endif
         
      }
      if(cstop!=NULL)
         *cstop = '\n';
      
      cstart = cstop+1;
   }
   
}

/************************************************************************/
int ExpandRange(char *range, int *residues)
{
   int nResidues = 0,
      start = 0,
      stop = 0,
      i;
   char *dotdot,
      *value;
   
   value = strrchr(range, ' ') + 1;
   
   if((dotdot=strstr(value, ".."))!=NULL)
   {
      *dotdot = '\0';
      start = atoi(value);
      stop = atoi(dotdot+2);
      for(i=start; i<=stop; i++)
      {
         residues[nResidues++] = i;
      }
   }
   else
   {
      residues[0] = atoi(value);
      nResidues = 1;
   }

   return(nResidues);
}



/************************************************************************/
void CalculateFeatureDistances(FEATURES *features, char *resid, char *infile)
{
   FILE *fp = NULL;
   PDB  *pdb = NULL;
   char chain[MAXLABEL],
      insert[MAXLABEL];
   int resnum, natoms;

   blParseResSpec(resid, chain, &resnum, insert);
   
   if((fp=fopen(infile, "r"))!=NULL)
   {
      if((pdb=blReadPDBAtoms(fp, &natoms))!=NULL)
      {
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NActSite,    features->ActSite,      &(features->MinDistActSite));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NBinding,    features->Binding,      &(features->MinDistBinding));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NCABinding,  features->CABinding,    &(features->MinDistCABinding));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NDNABinding, features->DNABinding,   &(features->MinDistDNABinding));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NNPBinding,  features->NPBinding,    &(features->MinDistNPBinding));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NMetal,      features->Metal,        &(features->MinDistMetal));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NModRes,     features->ModRes,       &(features->MinDistModRes));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NCarbohyd,   features->Carbohyd,     &(features->MinDistCarbohyd));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NMotif,      features->Motif,        &(features->MinDistMotif));
         PopulateFeatureDistance(pdb, chain, resnum, insert, features->NLipid,      features->Lipid,        &(features->MinDistLipid));
      }
      else
      {
         fprintf(stderr,"No atoms read from PDB file: %s\n", infile);
         exit(1);
      }
   }
   else
   {
      fprintf(stderr,"Unable to open file: %s\n", infile);
      exit(1);
   }
}

/************************************************************************/
void Usage(void)
{

}

/************************************************************************/
PDBSWS *ParsePDBSWSResponse(char *response)
{
   char   *body   = response;
   PDBSWS *pdbsws = NULL,
          *p      = NULL;
   BOOL   more    = FALSE;
   char   *slashslash = NULL;

   if(response == NULL)
      return(NULL);
   
   if(strstr(body, "400 Bad Request"))
   {
      fprintf(stderr, "sprotFTDist: 400 Bad Request\n");
      exit(1);
   }
   
   do{
      if(p==NULL)
      {
         INIT(pdbsws, PDBSWS);
         p = pdbsws;
      }
      else
      {
         ALLOCNEXT(p, PDBSWS);
      }
      if(p==NULL)
      {
         fprintf(stderr,"No memory for PDBSWS data\n");
         exit(1);
      }
      
      CopyItem(body, "PDB: ",     p->pdb);
      CopyItem(body, "CHAIN: ",   p->chain);
      CopyItem(body, "RESID: ",   p->resid);
      CopyItem(body, "PDBAA: ",   p->pdbaa);
      CopyItem(body, "AC: ",      p->ac);
      CopyItem(body, "ID: ",      p->id);
      CopyItem(body, "UPCOUNT: ", p->upcount);
      CopyItem(body, "AA: ",      p->aa);

      /* Move on to next entry */
      more = FALSE;
      if((slashslash = strstr(body, "//"))!=NULL)
         body = slashslash+2;

      if((slashslash = strstr(body, "//"))!=NULL)
         more = TRUE;
   }  while(more);

   return(pdbsws);
}

/************************************************************************/
void CopyItem(char *body, char *key, char *dest)
{
   char buffer[MAXBUFF],
      *chp;
   if(dest!=NULL)
   {
      *dest = '\0';
      if((chp=strstr(body, key))!=NULL)
      {
         chp += strlen(key);
         
         strncpy(buffer, chp, MAXBUFF-1);
         if((chp = strchr(buffer, '\n'))!=NULL)
         {
            *chp = '\0';
         }
         
         strncpy(dest, buffer, SMALLBUFF-1);
      }
   }
}

/************************************************************************/
char *RunExternal(char *cmd)
{
   FILE *fp;
   char buffer[MAXBUFF],
      *result=NULL;

   if ((fp = popen(cmd, "r")) == NULL)
   {
      fprintf(stderr,"Error opening pipe!\n");
      return(NULL);
   }

   while (fgets(buffer, MAXBUFF, fp) != NULL)
   {
      result=blStrcatalloc(result, buffer);
   }

    if(pclose(fp))
    {
       fprintf(stderr,"Command not found or exited with error status: %s\n", cmd);
       return(NULL);
    }

    return(result);
}


/************************************************************************/
void PopulateFeatureDistance(PDB *pdb, char *chain, int resnum, char *insert,
                             int nRes, char resids[MAXSITE][MAXLABEL], REAL *minDist)
{
   PDB *keyRes, *keyResNext,
      *ftRes, *ftResNext;

   if(nRes)
   {
      if((keyRes = blFindResidue(pdb, chain, resnum, insert))!=NULL)
      {
         REAL minFtDist = (REAL)100000.0;
         int i;
         keyResNext = blFindNextResidue(keyRes);

         for(i=0; i<nRes; i++)
         {
            char ftChain[MAXLABEL], ftInsert[MAXLABEL];
            int  ftResnum;
            blParseResSpec(resids[i], ftChain, &ftResnum, ftInsert);
            if((ftRes = blFindResidue(pdb, chain, ftResnum, ftInsert))!=NULL)
            {
               PDB  *p, *q;
               
               ftResNext = blFindNextResidue(ftRes);
               for(p=keyRes; p!=keyResNext; NEXT(p))
               {
                  for(q=ftRes; q!=ftResNext; NEXT(q))
                  {
                     REAL dist = DIST(p, q);
                     if(dist < minFtDist)
                     {
                        minFtDist = dist;
                     }
                  }
               }
            }
         }

         if(((*minDist < 0.0) || (minFtDist < *minDist)) &&
            (minFtDist < (99999.0)))
         {
            *minDist = minFtDist;
         }
      }
   }
}




/************************************************************************/
void PrintResults(FEATURES features)
{
   if(((features.MinDistActSite > (-0.5))    && (features.MinDistActSite < BADCUTDIST)) ||
      ((features.MinDistBinding > (-0.5))    && (features.MinDistBinding < BADCUTDIST)) ||
      ((features.MinDistCABinding > (-0.5))  && (features.MinDistCABinding < BADCUTDIST)) ||
      ((features.MinDistDNABinding > (-0.5)) && (features.MinDistDNABinding < BADCUTDIST)) ||
      ((features.MinDistNPBinding > (-0.5))  && (features.MinDistNPBinding < BADCUTDIST)) ||
      ((features.MinDistMetal > (-0.5))      && (features.MinDistMetal < BADCUTDIST)) ||
      ((features.MinDistModRes > (-0.5))     && (features.MinDistModRes < BADCUTDIST)) ||
      ((features.MinDistCarbohyd > (-0.5))   && (features.MinDistCarbohyd < BADCUTDIST)) ||
      ((features.MinDistMotif > (-0.5))      && (features.MinDistMotif < BADCUTDIST)) ||
      ((features.MinDistLipid > (-0.5))      && (features.MinDistLipid < BADCUTDIST)))
   {
      printf("{\"SprotFTdist-BOOL\": \"BAD\"");
   }
   else
   {
      printf("{\"SprotFTdist-BOOL\": \"OK\"");
   }
      
   PrintAResult("SprotFTdist-ACT_SITE", features.MinDistActSite);
   PrintAResult("SprotFTdist-BINDING",  features.MinDistBinding);
   PrintAResult("SprotFTdist-CA_BIND",  features.MinDistCABinding);
   PrintAResult("SprotFTdist-DNA_BIND", features.MinDistDNABinding);
   PrintAResult("SprotFTdist-NP_BIND",  features.MinDistNPBinding);
   PrintAResult("SprotFTdist-METAL",    features.MinDistMetal);
   PrintAResult("SprotFTdist-MOD_RES",  features.MinDistModRes);
   PrintAResult("SprotFTdist-CARBOHYD", features.MinDistCarbohyd);
   PrintAResult("SprotFTdist-MOTIF",    features.MinDistMotif);
   PrintAResult("SprotFTdist-LIPID",    features.MinDistLipid);

   printf("}\n");
}

/************************************************************************/
void PrintAResult(char *label, REAL dist)
{
   int i;
   
   printf(", \"%s\": \"%.3f\"", label, dist);
}

#ifdef PRINTFEATURES
/************************************************************************/
void PrintFeatures(FEATURES features)
{
   PrintAFeature("SprotFTdist-ACT_SITE", features.NActSite, features.ActSite, features.MinDistActSite);
   PrintAFeature("SprotFTdist-BINDING",  features.NBinding, features.Binding, features.MinDistBinding);
   PrintAFeature("SprotFTdist-CA_BIND",  features.NCABinding, features.CABinding, features.MinDistCABinding);
   PrintAFeature("SprotFTdist-DNA_BIND", features.NDNABinding, features.DNABinding, features.MinDistDNABinding);
   PrintAFeature("SprotFTdist-NP_BIND",  features.NNPBinding, features.NPBinding, features.MinDistNPBinding);
   PrintAFeature("SprotFTdist-METAL",    features.NMetal, features.Metal, features.MinDistMetal);
   PrintAFeature("SprotFTdist-MOD_RES",  features.NModRes, features.ModRes, features.MinDistModRes);
   PrintAFeature("SprotFTdist-CARBOHYD", features.NCarbohyd, features.Carbohyd, features.MinDistCarbohyd);
   PrintAFeature("SprotFTdist-MOTIF",    features.NMotif, features.Motif, features.MinDistMotif);
   PrintAFeature("SprotFTdist-LIPID",    features.NLipid, features.Lipid, features.MinDistLipid);
}

/************************************************************************/
void PrintAFeature(char *label, int nres, char resids[MAXSITE][MAXLABEL], REAL dist)
{
   int i;
   
   fprintf(stderr, "%s: (%d)", label, nres);
   for(i=0; i<nres; i++)
   {
      fprintf(stderr, " %s", resids[i]);
   }
   fprintf(stderr, " [%.3f]\n", dist);
}
#endif
