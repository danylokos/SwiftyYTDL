//
//  YTDLKit-Private.h
//  SwiftyYTDL
//
//  Created by Danylo Kostyshyn on 20.07.2022.
//

#ifndef YTDLKit_Private_h
#define YTDLKit_Private_h

void Py_Initialize(void);

void PyEval_InitThreads(void);

int PyRun_SimpleString(const char *);

void Py_Finalize(void);

#endif /* YTDLKit_Private_h */
