; Jump targets for the ]] / [[ / ][ / [] section motions (see polish.lua).
;
; @function.outer / @class.outer (textobjects.scm) capture BOTH the
; decorated_definition and the bare *_definition, so their start sits on the
; @decorator line and ]] stops twice per decorated def (once on @classmethod,
; once on def). Matching only the bare definition node lands the motion on the
; def / class keyword: in a decorated_definition the *_definition child begins
; after the decorators, so they are skipped. Decorators still belong to the
; af / ac SELECTION, which keeps using @function.outer / @class.outer.
(function_definition) @def
(class_definition) @def
