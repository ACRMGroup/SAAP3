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
   struct _features *next;
}  FEATURES;

typedef struct 
{
   char pdb[SMALLBUFF],
      chain[MAXLABEL],
      resid[MAXLABEL],
      pdbaa[MAXLABEL],
      ac[SMALLBUFF],
      id[SMALLBUFF],
      upcount[MAXLABEL],
      aa[MAXLABEL];
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
void MapFeaturesToPDB(FEATURES *features);
void CalculateFeatureDistances(FEATURES *features, char *resid,
                               char *infile);
void PrintResults(FEATURES *features);
void Usage(void);
void CopyItem(char *body, char *key, char *dest);
void ParsePDBSWSResponse(struct http_response *httpResponse, PDBSWS *pdbsws);
char *RunExternal(char *cmd);
void SetFeature(char *text, char *feature, int *nfeature, int *residues);






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
      FindPDBCode(infile, pdbcode);
      FindUniProtCode(pdbcode, resid, uniprotcode);
      printf("UP: %s\n", uniprotcode);
      features = FindFeatures(uniprotcode);
      
#ifdef REAL
      MapFeaturesToPDB(features);
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
   PDBSWS pdbsws;
   
   blParseResSpec(resid, chain, &resnum, insert);
   sprintf(url, "%s&qtype=pdb&id=%s&chain=%s&res=%d", SERVERURL, pdbcode, chain, resnum);
   /*
   http://www.bioinf.org.uk/servers/pdbsws/query.cgi?plain=1&qtype=pdb&id=3u1n&chain=A&res=123
   */
   httpResponse = http_get(url, "User-agent:sprotFTdist\r\n");
   ParsePDBSWSResponse(httpResponse, &pdbsws);
   strcpy(uniprotcode, pdbsws.ac);
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

void SetFeature(char *text, char *feature, int *nfeature, int *residues)
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
         printf("%s\n", cstart); 
         
      }
      if(cstop!=NULL)
         *cstop = '\n';
      
      cstart = cstop+1;
   }
   
}




void MapFeaturesToPDB(FEATURES *features)
{

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

void ParsePDBSWSResponse(struct http_response *httpResponse, PDBSWS *pdbsws)
{
   char *body = httpResponse->body;
   CopyItem(body, "PDB: ",     pdbsws->pdb);
   CopyItem(body, "CHAIN: ",   pdbsws->chain);
   CopyItem(body, "RESID: ",   pdbsws->resid);
   CopyItem(body, "PDBAA: ",   pdbsws->pdbaa);
   CopyItem(body, "AC: ",      pdbsws->ac);
   CopyItem(body, "ID: ",      pdbsws->id);
   CopyItem(body, "UPCOUNT: ", pdbsws->upcount);
   CopyItem(body, "AA: ",      pdbsws->aa);
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
