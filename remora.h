/*
 * adv_stats.h
 *
 *  Created on: Sep 14, 2017
 *      Author: florian
 */

#ifndef REMORA_H_
#define REMORA_H_

#include <stdio.h>

#include <opencv2/core/core.hpp>
using namespace cv;

#define MAX_EVENTS 65535
#define MAX_TIMERS 65535

#define REMORA_IN 0
#define REMORA_OUT 1

#define FUNCTION_IN 10
#define FUNCTION_OUT 11
#define FUNCTION_CUDA_IN 12
#define FUNCTION_CUDA_OUT 13

#define LOOP_IN 20
#define LOOP_NEST_IN 21
#define LOOP_OUT 22
#define LOOP_NEST_OUT 23
#define LOOP_ITER 24
#define LOOP_NEST_ITER 25

#define TIMER_IN 30
#define TIMER_OUT 31
#define TIMER_LAP 32

#define ARRAY_ALLOC 40
#define ARRAY_INIT 41
#define ARRAY_FREE 42
#define ARRAY_REDEFINED 43

#define MEMORY_TRANSFERT_IN 50
#define MEMORY_TRANSFERT_OUT 51

#define REM_INFO 90

#define REMORA_INIT ;
#define REMORA_START addEvent("",__FUNCTION__,__LINE__,REMORA_IN);
#define REMORA_STOP addEvent("",__FUNCTION__,__LINE__,REMORA_OUT);
#define REMORA_EXIT remoraHalt();
#define REMORA_EXPORT(a) saveResults(a);

#define FCT_IN addEvent("",__FUNCTION__,__LINE__,FUNCTION_IN);
#define FCT_OUT addEvent("",__FUNCTION__,__LINE__,FUNCTION_OUT);
#define FCT_CUDA_IN cudaDeviceSynchronize();addEvent("",__FUNCTION__,__LINE__,FUNCTION_CUDA_IN);
#define FCT_CUDA_OUT cudaDeviceSynchronize();addEvent("",__FUNCTION__,__LINE__,FUNCTION_CUDA_OUT);
#define FCT_CUDA_IN_N(a) cudaDeviceSynchronize();addEvent("",a,__LINE__,FUNCTION_CUDA_IN);
#define FCT_CUDA_OUT_N(a) cudaDeviceSynchronize();addEvent("",a,__LINE__,FUNCTION_CUDA_OUT);

#define MEM_TRANSF_IN cudaDeviceSynchronize();addEvent("","Mem. transf.",__LINE__,MEMORY_TRANSFERT_IN);
#define MEM_TRANSF_OUT cudaDeviceSynchronize();addEvent("","Mem. transf.",__LINE__,MEMORY_TRANSFERT_OUT);

#define LP_IN(b) addEvent(b,__FUNCTION__,__LINE__,LOOP_IN);
#define LPN_IN(a) addEvent(a,__FUNCTION__,__LINE__,LOOP_NEST_IN);
#define LP_OUT addEvent("",__FUNCTION__,__LINE__,LOOP_OUT);
#define LPN_OUT addEvent("",__FUNCTION__,__LINE__,LOOP_NEST_OUT);
#define LP_ITER addEvent("",__FUNCTION__,__LINE__,LOOP_ITER);
#define LPN_ITER(a);// addEvent("",__FUNCTION__,__LINE__,LOOP_NEST_ITER);

#define AR_ALLOC(a) addEvent(a,__FUNCTION__,__LINE__,ARRAY_ALLOC);
#define AR_INIT(a) addEvent(a,__FUNCTION__,__LINE__,ARRAY_INIT);
#define AR_FREE(a)	addEvent(a,__FUNCTION__,__LINE__,ARRAY_FREE);
#define AR_REDEFINED(a) addEvent(a,__FUNCTION__,__LINE__,ARRAY_REDEFINED);

#define LOG_INFO(a) addEvent(a,__FUNCTION__,__LINE__,REM_INFO);

#define REMORA_DISPLAY displayEvents();displayFunctionsStats();displayFunctionsStats_light();
#define REMORA_DISPLAY_CSV displayCSVevents();
#define REMORA_DISPLAY_SECTORS sectorDiagram_datas();
#define REMORA_DISPLAY_LATEX_TABLE displayLatexTable();

void addTime(unsigned int numTimer, int64 time);
double getTimer(unsigned int numTimer);
void initTimer(unsigned int numTimer);

void addIter(const char* info,const char* function,const unsigned int line, unsigned char event_type_p);
void addEvent(const char* info,const char* function,const unsigned int line, unsigned char event_type_p);
void displayEvents();
void displayFunctionsStats_light();
void displayFunctionsStats();
void displayCSVevents();
void sectorDiagram_datas();
void displayLatexTable();
void remoraHalt();

void saveResults(const char* filename);

#endif /* REMORA_H_ */
