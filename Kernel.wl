BeginPackage["Notebook`Kernel`PrintRedirect`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`Misc`Async`",
    "Notebook`CellOperations`"
}];

Begin["`Internal`"]

time = AbsoluteTime[];
cnt = 0;

DefineOutputStreamMethod["MasterEchoPrint",
   {
      "ConstructorFunction" -> 
   Function[{streamname, isAppend, caller, opts},
    With[{state = Unique["PassthroughOutputStream"]},
     state["pos"] = 0;
     {True, state}
     ] ],
  
  "CloseFunction" -> 
   Function[state,  ClearAll[state] ],
  
  "StreamPositionFunction" -> Function[state, {state["pos"], state}],
  
  "WriteFunction" ->
   Function[{state, bytes},
    Module[{result, nBytes},
     nBytes = Length[bytes];
     Block[{$Output = {}},
        With[{str = bytes // ByteArray // ByteArrayToString // StringTrim},
            If[StringLength[str] > 0 && str =!= "Null" && str =!= ">> Null" && !StringMatchQ[str, "OutputStream"~~__],
                
                If[AbsoluteTime[] - time > 1,
                    time = AbsoluteTime[];
                    cnt = 0;
                ];

               If[cnt >= 0, 

                cnt = cnt + 1;

                If[cnt > 7,
                    cnt = -1;
                    EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage["System"], "Too many print messages. The output was suppressed"]; 
                ,

                    If[AssociationQ[Global`$EvaluationContext],
                        CellPrint[str, "Display"->"print"];
                    ,
                        EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage["Print"], str]; 
                    ];       
                ]; 
              ];    
            ];
        ];
     ];
     state["pos"] += nBytes;
     {nBytes, state}
     ]
    ]
  }
]

DefineOutputStreamMethod["MasterEchoWarning",
   {
      "ConstructorFunction" -> 
   Function[{streamname, isAppend, caller, opts},
    With[{state = Unique["PassthroughOutputStream2"]},
     state["pos"] = 0;
     {True, state}
     ] ],
  
  "CloseFunction" -> 
   Function[state,  ClearAll[state]],
  
  "StreamPositionFunction" -> Function[state, {state["pos"], state}],
  
  "WriteFunction" ->
   Function[{state, bytes},
    Module[{result, nBytes},
     nBytes = Length[bytes];
     Block[{$Output = {}},
        With[{str = bytes // ByteArray // ByteArrayToString // StringTrim},
            If[StringLength[str] > 0 && str =!= "Null", EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], "Warning", str] ]; 
        ];
     ];
     state["pos"] += nBytes;
     {nBytes, state}
     ]
    ]
  }
]

OverrideListener := With[{},
    If[Internal`Kernel`Type =!= "LocalKernel",
        Echo["Error. PrintRedirect package can only for on LocalKernel. MasterKernel is not allowed!"];
    ,
        $Messages = {OpenWrite[Method -> "MasterEchoWarning"]};
        $Output = {OpenWrite[Method -> "MasterEchoPrint"]};      
    ];
];



End[]
EndPackage[]