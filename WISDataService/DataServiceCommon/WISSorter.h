//
//  WISSorter.h
//  WisdriIS
//
//  Created by Jingwei Wu on 5/30/16.
//  Copyright © 2016 Wisdri. All rights reserved.
//

#ifndef WISSorter_h
#define WISSorter_h


#endif /* WISSorter_h */

typedef NSComparisonResult (^arrayForwardSorterWithResult)(id lhs, id rhs);
typedef NSComparisonResult (^arrayBackwardSorterWithResult)(id lhs, id rhs);

typedef BOOL (^arrayForwardSorterWithBOOL)(id lhs, id rhs);
typedef BOOL (^arrayBackwardSorterWithBOOL)(id lhs, id rhs);