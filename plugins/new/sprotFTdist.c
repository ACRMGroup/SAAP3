/*
SetFeature() gets the feature lines, but needs to parse out the residue number(s)
and store those data 
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "bioplib/pdb.h"
#include "bioplib/macros.h"
#include "bioplib/MathType.h"

#define MAXLABEL  8
#define SMALLBUFF 16
#define MAXBUFF   256
#define MAXSITE   100

typedef struct _features
{
   int NActSite, ActSite[MAXSITE];
   int NBinding, Binding[MAXSITE];
   int NCABinding, CABinding[MAXSITE];
   int NDNABinding, DNABinding[MAXSITE];
   int NNPBinding, NPBinding[MAXSITE];
   int NMetal, MetalBinding[MAXSITE];
   int NModRes, ModRes[MAXSITE];
   int NCarbohyd, Carbohyd[MAXSITE];
   int NMotif, Motif[MAXSITE];
   int NLipid, Lipid[MAXSITE];
}  FEATURES;

typedef struct _pdbsws
{
   char pdb[SMALLBUFF],
      chain[MAXLABEL],
      resid[MAXLABEL],
      pdbaa[MAXLABEL],
      ac[SMALLBUFF],
      id[SMALLBUFF],
      upcount[MAXLABEL],
      aa[MAXLABEL];
   struct _pdbsws *next;
}  PDBSWS;


/*
	Represents an url
*/
struct parsed_url 
{
	char *uri;					/* mandatory */
    char *scheme;               /* mandatory */
    char *host;                 /* mandatory */
	char *ip; 					/* mandatory */
    char *port;                 /* optional */
    char *path;                 /* optional */
    char *query;                /* optional */
    char *fragment;             /* optional */
    char *username;             /* optional */
    char *password;             /* optional */
};

/*
	Represents an HTTP html response
*/
struct http_response
{
	struct parsed_url *request_uri;
	char *body;
	char *status_code;
	int status_code_int;
	char *status_text;
	char *request_headers;
	char *response_headers;
};


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
void MapFeature(char *label, char *upcode, char *pdbcode, char *chain, int nres, int *res);
void CalculateFeatureDistances(FEATURES *features, char *resid,
                               char *infile);
void PrintResults(FEATURES *features);
void Usage(void);
void CopyItem(char *body, char *key, char *dest);
PDBSWS *ParsePDBSWSResponse(struct http_response *httpResponse);
char *RunExternal(char *cmd);
void SetFeature(char *text, char *feature, int *nfeature, int *residues);
int ExpandRange(char *range, int *residues);
void FindPDBResFromUniProt(char *upcode, int upnum, char *pdbcode, char *chain, char *resid);



#ifdef DEBUG
void PrintFeature(char *label, int nres, int *res);
void PrintFeatures(FEATURES features);
#endif







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
      FindUniProtCode(pdbcode, resid, uniprotcode);
      printf("UP: %s\n", uniprotcode);
      features = FindFeatures(uniprotcode);
#ifdef DEBUG
      PrintFeatures(features);
#endif
      blParseResSpec(resid, chain, &resnum, insert);
      MapFeaturesToPDB(&features, uniprotcode, pdbcode, chain);
      
#ifdef REAL
      CalculateFeatureDistances(features, resid, infile);
      PrintResults(features);
#endif
   }
   else
   {
      Usage();
   }
   
   return(0);
}


void MapFeaturesToPDB(FEATURES *features, char *upcode, char *pdbcode, char *chain)
{
   MapFeature("Active Site",  upcode, pdbcode, chain, features->NActSite,    features->ActSite);
   MapFeature("Binding",      upcode, pdbcode, chain, features->NBinding,    features->Binding);
   MapFeature("CA Binding",   upcode, pdbcode, chain, features->NCABinding,  features->CABinding);
   MapFeature("DNA Binding",  upcode, pdbcode, chain, features->NDNABinding, features->DNABinding);
   MapFeature("NP Binding",   upcode, pdbcode, chain, features->NNPBinding,  features->NPBinding);
   MapFeature("Metal",        upcode, pdbcode, chain, features->NMetal,      features->MetalBinding);
   MapFeature("ModRes",       upcode, pdbcode, chain, features->NModRes,     features->ModRes);
   MapFeature("Carbohydrate", upcode, pdbcode, chain, features->NCarbohyd,   features->Carbohyd);
   MapFeature("Motif",        upcode, pdbcode, chain, features->NMotif,      features->Motif);
   MapFeature("Lipid",        upcode, pdbcode, chain, features->NLipid,      features->Lipid);
}

void MapFeature(char *label, char *upcode, char *pdbcode, char *chain, int nres, int *res)
{
   int i;
   char resid[SMALLBUFF];
   

   fprintf(stderr, "%s: ", label);
   for(i=0; i<nres; i++)
   {
      FindPDBResFromUniProt(upcode, res[i], pdbcode, chain, resid);
      fprintf(stderr, " %d %s", res[i], resid);
   }
   fprintf(stderr, "\n");


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


void FindPDBCode(char *infile, char *pdbcode)
{
   strcpy(pdbcode, blFNam2PDB(infile));
}

void FindUniProtCode(char *pdbcode, char *resid, char *uniprotcode)
{
   char chain[MAXLABEL],
      insert[MAXLABEL],
      url[MAXBUFF];
   int  resnum;
   struct http_response *httpResponse;
   PDBSWS *pdbsws = NULL;
   
   blParseResSpec(resid, chain, &resnum, insert);
   sprintf(url, "%s&qtype=pdb&id=%s&chain=%s&res=%d%s", SERVERURL, pdbcode, chain, resnum, insert);
   KILLTRAILSPACES(url);
   fprintf(stderr,"URL: %s\n", url);
   /*
   http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=pdb&id=3u1n&chain=A&res=123
   */
   httpResponse = http_get(url, "User-agent:sprotFTdist\r\n");
   if((pdbsws = ParsePDBSWSResponse(httpResponse))!=NULL)
   {
      strcpy(uniprotcode, pdbsws->ac);
      FREELIST(pdbsws, PDBSWS);
   }
   
}

void FindPDBResFromUniProt(char *upcode, int upnum, char *pdbcode, char *chain, char *resid)
{
   char   url[MAXBUFF];
   int    resnum;
   struct http_response *httpResponse;
   PDBSWS *pdbsws = NULL;
   
   sprintf(url, "%s&qtype=ac&id=%s&res=%d", SERVERURL, upcode, upnum);
   KILLTRAILSPACES(url);
   fprintf(stderr,"URL: %s\n", url);
   
   /*
   http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=ac&id=Q9Y3Z3&res=137
   */
   httpResponse = http_get(url, "User-agent:sprotFTdist\r\n");
   if((pdbsws=ParsePDBSWSResponse(httpResponse))!=NULL)
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
}

FEATURES FindFeatures(char *uniprotcode)
{
   FEATURES features;
   struct http_response *httpResponse;
   char url[MAXBUFF];
   char cmd[MAXBUFF];
   char *result;

   sprintf(url, "%s%s.txt", UNIPROTURL, uniprotcode);
   sprintf(cmd, "/usr/bin/curl -s %s", url);

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
   
   SetFeature(result, "ACT_SITE", &(features.NActSite),    features.ActSite);
   SetFeature(result, "BINDING",  &(features.NBinding),    features.Binding);
   SetFeature(result, "CA_BIND",  &(features.NCABinding),  features.CABinding);
   SetFeature(result, "DNA_BIND", &(features.NDNABinding), features.DNABinding);
   SetFeature(result, "NP_BIND",  &(features.NNPBinding),  features.NPBinding);
   SetFeature(result, "METAL",    &(features.NMetal),      features.MetalBinding);
   SetFeature(result, "MOD_RES",  &(features.NModRes),     features.ModRes);
   SetFeature(result, "CARBOHYD", &(features.NCarbohyd),   features.Carbohyd);
   SetFeature(result, "MOTIF",    &(features.NMotif),      features.Motif);
   SetFeature(result, "LIPID",    &(features.NLipid),      features.Lipid);
   
   return(features);
}

void SetFeature(char *text, char *feature, int *nFtResidues, int *ftResidues)
{
   char *cstart, *cstop;
   char key[MAXBUFF];

   sprintf(key, "FT   %s", feature);

   cstart=text;
   while((cstart!=NULL) && (cstop!=NULL) && (*cstart != '\0'))
   {
      if((cstop = strchr(cstart, '\n'))!=NULL)
      {
         *cstop = '\0';
      }
      
      if(!strncmp(cstart, key, strlen(key)))
      {
         int residues[MAXSITE];
         int nInRange;
         int i;
            
         nInRange = ExpandRange(cstart, residues);
         for(i=0; i<nInRange; i++)
         {
            ftResidues[*nFtResidues] = residues[i];
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



void CalculateFeatureDistances(FEATURES *features, char *resid,
                               char *infile)
{

}

void PrintResults(FEATURES *features)
{

}

void Usage(void)
{

}

PDBSWS *ParsePDBSWSResponse(struct http_response *httpResponse)
{
   char   *body   = httpResponse->body;
   PDBSWS *pdbsws = NULL,
          *p      = NULL;
   BOOL   more    = FALSE;
   char   *slashslash = NULL;

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
         NEXT(p);
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

void CopyItem(char *body, char *key, char *dest)
{
   char buffer[MAXBUFF],
      *chp;
   *dest = '\0';
   if((chp=strstr(body, key))!=NULL)
   {
      chp += strlen(key);
      
      strcpy(buffer, chp);
      if((chp = strchr(buffer, '\n'))!=NULL)
      {
         *chp = '\0';
      }
      strcpy(dest, buffer);
   }
}

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
       fprintf(stderr,"Command not found or exited with error status\n");
       return(NULL);
    }

    return(result);
}

#ifdef DEBUG
void PrintFeatures(FEATURES features)
{
   PrintFeature("Active Site", features.NActSite, features.ActSite);
   PrintFeature("Binding", features.NBinding, features.Binding);
   PrintFeature("CA Binding", features.NCABinding, features.CABinding);
   PrintFeature("DNA Binding", features.NDNABinding, features.DNABinding);
   PrintFeature("NP Binding", features.NNPBinding, features.NPBinding);
   PrintFeature("Metal", features.NMetal, features.MetalBinding);
   PrintFeature("ModRes", features.NModRes, features.ModRes);
   PrintFeature("Carbohydrate", features.NCarbohyd, features.Carbohyd);
   PrintFeature("Motif", features.NMotif, features.Motif);
   PrintFeature("Lipid", features.NLipid, features.Lipid);
}

void PrintFeature(char *label, int nres, int *res)
{
   int i;
   
   fprintf(stderr, "%s: (%d)", label, nres);
   for(i=0; i<nres; i++)
   {
      fprintf(stderr, " %d", res[i]);
   }
   fprintf(stderr, "\n");
}
#endif
