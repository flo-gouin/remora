#include "remora.h"

struct event{
	int64 time;
	unsigned int event_type;
	unsigned int line;
	char function[64];
	char info[128];
};

event *eventTab = (event*) malloc(MAX_EVENTS * sizeof(event));
//event eventTab[MAX_EVENTS];
unsigned int nbEvent = 0;

int64 timerTab[MAX_TIMERS];

void addTime(unsigned int numTimer, int64 time){
	timerTab[numTimer] += time;
}

double getTimer(unsigned int numTimer){
	return timerTab[numTimer]/getTickFrequency()*1000.0;
}

void initTimer(unsigned int numTimer){
	timerTab[numTimer] = 0;
}

//========== Console functionalities
char indentTab[128] = "\0";

void fctIndent(){
	strcat(indentTab,".	");
}

void loopIndent(){
	strcat(indentTab,"(	");
}

void indent(){
	strcat(indentTab,"	");
}

void unIndent(){
	indentTab[strlen(indentTab)-1] = '\0';
	indentTab[strlen(indentTab)-1] = '\0';
}

void unIndent2(){
	indentTab[strlen(indentTab)-1] = '\0';
	indentTab[strlen(indentTab)-1] = '\0';
}
//=========== End of console functionalities

void remoraHalt(){
	free(eventTab);
	nbEvent = 0;
}

void addIter(const char* info,const char* function,const unsigned int line, unsigned char event_type_p){

}

void addEvent(const char* info,const char* function,const unsigned int line, unsigned char event_type_p){
	if(nbEvent < MAX_EVENTS){
		eventTab[nbEvent].time = getTickCount();
		eventTab[nbEvent].event_type = event_type_p;
		eventTab[nbEvent].line = line;
		strcpy(eventTab[nbEvent].function,function);
		strcpy(eventTab[nbEvent].info,info);
		nbEvent++;
	} else {
		printf("Error: max events limit reached!");
		exit(1);
	}
}

double deltaTime(event eventB , event eventA){
	return (eventB.time - eventA.time)/getTickFrequency()*1000.0;
}

double getTime(event event_p){
	return deltaTime(event_p,eventTab[0]);
}

event searchForNextCorrespondingEvent(int numStartEvent){
	event referingEvent = eventTab[numStartEvent];
	unsigned char targetEventType;
	unsigned int depth = 0;
	switch(referingEvent.event_type){
		case (LOOP_IN):
			targetEventType = LOOP_OUT;
			break;
		case (LOOP_NEST_IN):
			targetEventType = LOOP_NEST_OUT;
			break;
		case (FUNCTION_IN):
			targetEventType = FUNCTION_OUT;
			break;
		case (FUNCTION_CUDA_IN):
			targetEventType = FUNCTION_CUDA_OUT;
			break;
		case (MEMORY_TRANSFERT_IN):
			targetEventType = MEMORY_TRANSFERT_OUT;
			break;
	}
	for(int numEvent = numStartEvent +1; numEvent < nbEvent; numEvent++){
		if(eventTab[numEvent].event_type == referingEvent.event_type){
			depth++;
		} else if(eventTab[numEvent].event_type == targetEventType && depth>0){
			depth--;
		} else if(eventTab[numEvent].event_type == targetEventType && depth==0){
			return eventTab[numEvent];
		}
	}
	return referingEvent;
}

unsigned int computeIterations(int numStartEvent){
	unsigned int iterations = 0;
	event referingEvent = eventTab[numStartEvent];

	unsigned char targetEventType;
	unsigned int depth = 0;
	switch(referingEvent.event_type){
		case (LOOP_IN):
			targetEventType = LOOP_OUT;
			break;
		case (LOOP_NEST_IN):
			targetEventType = LOOP_NEST_OUT;
			break;
		}

	for(int numEvent = numStartEvent +1; numEvent < nbEvent; numEvent++){
		if(eventTab[numEvent].event_type == LOOP_NEST_ITER || eventTab[numEvent].event_type == LOOP_ITER){
			iterations++;
		} else if(eventTab[numEvent].event_type == referingEvent.event_type){
			depth++;
		} else if(eventTab[numEvent].event_type == targetEventType && depth>0){
			depth--;
		} else if(eventTab[numEvent].event_type == targetEventType && depth==0){
			return iterations;
		}
	}
	return iterations;
}

void displayCSVevents(){
	unsigned eventCounter = 0;

	for (int numEvent = 0; numEvent<nbEvent; numEvent++){
		event currEvent = eventTab[numEvent];
		switch(currEvent.event_type){
			case LOOP_OUT:
			case LOOP_NEST_OUT:
			case FUNCTION_OUT:
			case REMORA_IN:
			case REMORA_OUT:
			case REM_INFO:
			case LOOP_ITER:
			case LOOP_NEST_ITER:
			case MEMORY_TRANSFERT_OUT:
				continue;
		}

		switch(currEvent.event_type){
			case FUNCTION_IN:
			case LOOP_IN:
			case LOOP_NEST_IN:
			case MEMORY_TRANSFERT_IN:
				printf("%u	%.03lf\n",eventCounter,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
		}
		eventCounter++;
	}
}

void displayFunctionsStats_light(){
	printf("=== Function statistics ==================================\n");
	printf("  Function  | runtime(ms)\n");

	for (int numEvent = 0; numEvent<nbEvent; numEvent++){
		event currEvent = eventTab[numEvent];

		switch(currEvent.event_type){
			case FUNCTION_IN:
				printf("%.03lf\n",deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
			case FUNCTION_CUDA_IN:
				printf("%.03lf\n",deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
			case MEMORY_TRANSFERT_IN:
				printf("%.03lf\n",deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
		}
	}
}

void displayFunctionsStats(){
	printf("=== Function statistics ==================================\n");
	printf("  Function  | runtime(ms)\n");

	for (int numEvent = 0; numEvent<nbEvent; numEvent++){
		event currEvent = eventTab[numEvent];

		switch(currEvent.event_type){
			case FUNCTION_IN:
				printf("%s: %.03lfms \n",currEvent.function,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
			case FUNCTION_CUDA_IN:
				printf("[CUDA] %s: %.03lfms \n",currEvent.function,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
			case MEMORY_TRANSFERT_IN:
				printf("[MEMORY TRANSFERT] %s: %.03lfms \n",currEvent.function,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				break;
			
		}
	}
}

void sectorDiagram_datas() {
	printf("=== Sector diagram data ==================================\n");
	printf("tin	tout	lvl	name\n");
	unsigned int level = 0;

	double minTime = getTime(eventTab[1]);
	double maxTime = getTime(eventTab[nbEvent-2]);
	double deltaTime = maxTime - minTime;
	unsigned int resolution = 1;

	float maxSectorsSpace = 330.0;
//	float maxSectorsSpace = 330.0 * (deltaTime/1000.0) /46.248 ;

	printf("\\foreach \\time in {%u,%u,%u,...,%u}{\n",resolution,2*resolution,3*resolution,(int)(deltaTime/1000));
	printf("\\pgfmathparse{\\time*%f}\\let\\sectTime\\pgfmathresult;\n",maxSectorsSpace/(deltaTime/1000));
	printf("\\draw[dashed, color=gray!30] (\\sectTime:2) -- (\\sectTime:7.5);\n");
//	printf("\\draw[color=gray] (\\sectTime:8) node {\\time};\n");
	printf("}\n");

	printf("\\foreach \\time in {%u,%u,%u,...,%u}{\n",resolution,2*resolution,3*resolution,(int)(deltaTime/1000));
	printf("\\pgfmathparse{\\time*%f}\\let\\sectTime\\pgfmathresult;\n",maxSectorsSpace/(deltaTime/1000));
	printf("\\draw[color=gray] (\\sectTime:8) node {\\time};\n");
	printf("}\n");


	printf("\\draw (0:2) -- (0:8);\n");
	printf("\\draw (0:8) node[right] {0s};\n");
	printf("\\draw (%.01f:2) -- (%.01f:8);\n",maxSectorsSpace,maxSectorsSpace);
	printf("\\draw (%.01f:8) node[below right] {%.03fs};\n",maxSectorsSpace,deltaTime/1000.0);

	for (int numLevel = 0; numLevel <= 20; numLevel++) {
		printf("\\sectionLevel{%u}\n",numLevel+2);
		printf("\\draw (0:%.01f) node[below] {%u};\n",(float)(numLevel+2)+0.2,numLevel);
		unsigned int nbElement = 0;
		for (int numEvent = 0; numEvent < nbEvent; numEvent++) {
			event currEvent = eventTab[numEvent];

			if (level == numLevel) {
				nbElement++;
				switch (currEvent.event_type) {
				case LOOP_ITER:
				case LOOP_NEST_ITER:
					printf("\\sectionIter{%.03lf}{%u}\n",(getTime(currEvent)-minTime)/maxTime*maxSectorsSpace,level+2-1);
					break;
				case FUNCTION_IN:
					printf("\\sectionElt{%.03lf}{%.03lf}{%u}{$%s$}{gray!40}\n", (getTime(currEvent)-minTime)/maxTime*maxSectorsSpace,
							(getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/maxTime*maxSectorsSpace,
							level+2, currEvent.function);
					break;
				case FUNCTION_CUDA_IN:
					printf("\\sectionElt{%.03lf}{%.03lf}{%u}{$%s$}{green!75}\n", (getTime(currEvent)-minTime)/maxTime*maxSectorsSpace,
							(getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/maxTime*maxSectorsSpace,
							level+2, currEvent.function);
					break;
				case MEMORY_TRANSFERT_IN:
					printf("\\sectionElt{%.03lf}{%.03lf}{%u}{$%s$}{orange!50}\n", (getTime(currEvent)-minTime)/maxTime*maxSectorsSpace,
							(getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/maxTime*maxSectorsSpace,
							level+2, currEvent.function);
					break;
				case LOOP_IN:
				case LOOP_NEST_IN:
					printf("\\sectionElt{%.03lf}{%.03lf}{%u}{$%s$}{blue!40}\n", (getTime(currEvent)-minTime)/maxTime*maxSectorsSpace,
							(getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/maxTime*maxSectorsSpace,
							level+2, currEvent.info);
					break;
				}
			}
			switch (currEvent.event_type) {
			case FUNCTION_IN:
			case FUNCTION_CUDA_IN:
			case LOOP_IN:
			case LOOP_NEST_IN:
				level++;
				break;
			case FUNCTION_OUT:
			case FUNCTION_CUDA_OUT:
			case LOOP_OUT:
			case LOOP_NEST_OUT:
				level--;
				break;
			}
		}

		if (nbElement == 0)
			break;
	}
}

void displayEvents(){
	event stopEv = eventTab[nbEvent-1];

	printf("%u event(s) recorded during %.03lfms\n",nbEvent,getTime(stopEv));
	printf("#event | runtime(ms) | id |  line | event\n");
	printf("-------+-------------+----+-------+--------\n");

	for (int numEvent = 0; numEvent<nbEvent; numEvent++){
		event currEvent = eventTab[numEvent];
/*		switch(currEvent.event_type){
			case LOOP_OUT:
			case LOOP_NEST_OUT:
			case FUNCTION_OUT:
				unIndent2();
				continue;
			case LOOP_NEST_ITER:
				continue;
		}
*/
		printf("%6i | %11.03lf | %2u | %5u |",numEvent,getTime(currEvent),currEvent.event_type, currEvent.line);
		switch(currEvent.event_type){
			case REMORA_IN:
				printf("**Remora starts collecting metrics**\n");break;
			case REMORA_OUT:
				printf("**End of metrics collection by Remora**\n");break;
			case FUNCTION_IN:
				printf("%s>>%s (%.03lfms)\n",indentTab,currEvent.function,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				fctIndent();
				break;
			case FUNCTION_OUT:
				unIndent2();
				printf("%s<<%s\n",indentTab,currEvent.function);
				break;
			case FUNCTION_CUDA_IN:
				printf("%s>>[CUDA] %s (%.03lfms)\n",indentTab,currEvent.function,deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				fctIndent();
				break;
			case FUNCTION_CUDA_OUT:
				unIndent2();
				printf("%s<<%s\n",indentTab,currEvent.function);
				break;
			case LOOP_IN:
				printf("%s+loop: %s [%u] (%.03lfms)\n",indentTab,currEvent.info,computeIterations(numEvent),deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				loopIndent();
				break;
			case LOOP_OUT:
				unIndent2();
				printf("%s+loop: %s [%u]\n",indentTab,currEvent.info,computeIterations(numEvent));
				break;
			case LOOP_NEST_IN:
				printf("%s+loop nest: %s [%u] (%.03lfms)\n",indentTab,currEvent.info,computeIterations(numEvent),deltaTime(searchForNextCorrespondingEvent(numEvent),currEvent));
				loopIndent();
				break;
			case LOOP_NEST_OUT:
				unIndent2();
				printf("%s+loop: %s [%u]\n",indentTab,currEvent.info,computeIterations(numEvent));
				break;
			case LOOP_ITER:
				unIndent2();
				printf("%s+--------------%s\n",indentTab,currEvent.info);
				loopIndent();
				break;
			case REM_INFO:
				printf("%s[%s]\n",indentTab,currEvent.info);
				break;
			case ARRAY_INIT:
				printf("%sinit: %s[]\n",indentTab,currEvent.info);
				break;
			case ARRAY_ALLOC:
				printf("%sallocate: %s[]\n",indentTab,currEvent.info);
				break;
			case ARRAY_REDEFINED:
				printf("%spointer redefined: %s[]\n",indentTab,currEvent.info);
				break;
			case ARRAY_FREE:
				printf("%sMemory freed: %s[]\n",indentTab,currEvent.info);
				break;
			default:
				printf("%s%s\n",indentTab,currEvent.info);break;
		}
	}
}

void displayLatexTable(){
	printf("=== Latex Table Data Formated ==================================\n");

	printf("\\begin{longtable}{| c | | >{\\itshape\\scriptsize}c | >{\\itshape\\scriptsize}c | >{\\bfseries\\small}c |}\n");
	printf("\\hline\n");
	printf("\\textbf{Description} & \\textbf{Début} & \\textbf{Fin} & \\textbf{Durée}\\\\\n");
	printf("& \\emph{\\color{darkgray}(s)} & \\emph{\\color{darkgray}(s)} & \\emph{\\color{darkgray}(s)}\\\\\n");

	unsigned int level = 0;

	double minTime = getTime(eventTab[1]);
	double maxTime = getTime(eventTab[nbEvent-2]);
	
	for (int numLevel = 0; numLevel <= 20; numLevel++) {
		printf("\\hline\n");
		printf("\\multicolumn{4}{c}{\\color{darkgray}\\emph{niveau %i}}\\\\\n",numLevel);
		printf("\\hline\n");
	
		unsigned int nbElement = 0;
		for (int numEvent = 0; numEvent < nbEvent; numEvent++) {
			event currEvent = eventTab[numEvent];

			float tin, tout;
			if (level == numLevel) {
				nbElement++;
				switch (currEvent.event_type) {
				case LOOP_ITER:
				case LOOP_NEST_ITER:
					printf("\\hline\n");
					break;
				case FUNCTION_IN:
					tin = (getTime(currEvent)-minTime)/1000.0;
					tout = (getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/1000.0;
					printf("%s & %.03lf & %.03lf & %.03lf \\\\\n",currEvent.function,tin,tout,tout-tin);
					break;
				case FUNCTION_CUDA_IN:
					tin = (getTime(currEvent)-minTime)/1000.0;
					tout = (getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/1000.0;
					printf("%s & \\color{green!75}%.03lf & \\color{green!75}%.03lf & \\color{green!75}%.03lf \\\\\n",currEvent.function,tin,tout,tout-tin);
					break;
				case MEMORY_TRANSFERT_IN:
					tin = (getTime(currEvent)-minTime)/1000.0;
					tout = (getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/1000.0;
					printf("%s & \\color{orange!50}%.03lf & \\color{orange!50}%.03lf & \\color{orange!50}%.03lf \\\\\n",currEvent.function,tin,tout,tout-tin);
					break;
				case LOOP_IN:
				case LOOP_NEST_IN:
					tin = (getTime(currEvent)-minTime)/1000.0;
					tout = (getTime(searchForNextCorrespondingEvent(numEvent))-minTime)/1000.0;
					printf("$l_{elt}$ & \\color{blue!40}%.03lf & \\color{blue!40}%.03lf & \\color{blue!40}%.03lf \\\\\n",tin,tout,tout-tin);
					break;
				}
			}
			switch (currEvent.event_type) {
			case FUNCTION_IN:
			case FUNCTION_CUDA_IN:
			case LOOP_IN:
			case LOOP_NEST_IN:
				level++;
				break;
			case FUNCTION_OUT:
			case FUNCTION_CUDA_OUT:
			case LOOP_OUT:
			case LOOP_NEST_OUT:
				level--;
				break;
			}
		}

		if (nbElement == 0)
			break;
	}
	
	printf("\\hline\n");
	printf("\\caption{\\label{orig_times_exp}Temps d'exécution de l'algorithme simpleflow original sur la Tegra X1}\\\\\n");
	printf("\\end{longtable}\n");
}

void saveResults(const char* filename){
	printf("Writing file: %s\n",filename);

	FILE* file = fopen(filename,"wb");

	if(file == NULL){
		perror("Error accessing file");
		return;
	}

	size_t fileSize = fwrite(eventTab,sizeof(*eventTab),nbEvent,file);
	fclose(file);

	printf("%lu/%u data successfully written in file %s.\n",fileSize,nbEvent,filename);
}
