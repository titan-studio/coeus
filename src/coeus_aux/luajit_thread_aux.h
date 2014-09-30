#include "lua.h"

#ifdef _WIN32
#define WExport __declspec(dllexport)
#else
#define WExport
#endif

WExport void ljta_run(void* L);