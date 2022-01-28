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


typedef struct _features
{
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


/* External prototypes */
struct http_response* http_get(char *url, char *custom_headers);

/* Prototypes */
BOOL ParseCmdLine(int argc, char **argv, char *resid, char *newaa,
                  char *infile);
int main(int argc, char **argv);
void FindPDBCode(char *infile, char *pdbcode);
void FindUniProtCode(char *pdbcode, char *resid, char *uniprotcode);
FEATURES *FindFeatures(char *uniprotcode);
void MapFeaturesToPDB(FEATURES *features);
void CalculateFeatureDistances(FEATURES *features, char *resid,
                               char *infile);
void PrintResults(FEATURES *features);
void Usage(void);
void CopyItem(char *body, char *key, char *dest);
void ParsePDBSWSResponse(struct http_response *httpResponse, PDBSWS *pdbsws);




/************************************************************************/
int main(int argc, char **argv)
{
   char resid[SMALLBUFF],
        newaa[SMALLBUFF],
      infile[MAXBUFF],
      uniprotcode[SMALLBUFF],
      pdbcode[SMALLBUFF];
   FEATURES *features;
   
   
   if(ParseCmdLine(argc, argv, resid, newaa, infile))
   {
      FindPDBCode(infile, pdbcode);
      FindUniProtCode(pdbcode, resid, uniprotcode);
      printf("UP: %s\n", uniprotcode);
      
#ifdef REAL
      features = FindFeatures(uniprotcode);
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

FEATURES *FindFeatures(char *uniprotcode)
{
   FEATURES *features = NULL;
   return(features);
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

