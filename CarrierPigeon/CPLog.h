//
//  CPLog.h
//  CarrierPigeon
//
//  Created by Chris D'Angelo on 4/25/14.
//  Copyright (c) 2014 ColumbiaMobileComputing. All rights reserved.
//

#ifndef CarrierPigeon_CPLog_h
#define CarrierPigeon_CPLog_h

#define CPCarrierPigeonDebugLogEnabled // comment this line to disable CDLogs

#ifdef CPCarrierPigeonDebugLogEnabled
#define CPLog( ... ) NSLog( __VA_ARGS__ )
#else
#define CPLog( ... )
#endif

#endif
