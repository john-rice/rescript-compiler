  external _NaN : float = "NaN" [@@bs.val] 
  external isNaN : float -> bool = "" [@@bs.val]
  external isFinite : float -> bool = "" [@@bs.val]
  external toExponentialWithPrecision : float -> digits:int -> string = "toExponential" [@@bs.send]
  external toFixed : float -> string = "" [@@bs.send]
  external toFixedWithPrecision : float -> digits:int -> string = "toFixed" [@@bs.send]
  external fromString : string -> float = "Number" [@@bs.val]