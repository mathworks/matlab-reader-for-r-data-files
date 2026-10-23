classdef RType < uint32
    %RTYPE R SEXPTYPE and serialization pseudo-type values.
    %   Core SEXPTYPE values match R's Rinternals.h enumeration. Values
    %   above the public SEXPTYPE range are R serialization pseudo-values
    %   used for references, environments, missing arguments, and ALTREP
    %   records.

    % Copyright 2026 The MathWorks, Inc.

    enumeration
        NILSXP (0)
        SYMSXP (1)
        LISTSXP (2)
        CLOSXP (3)
        ENVSXP (4)
        PROMSXP (5)
        LANGSXP (6)
        SPECIALSXP (7)
        BUILTINSXP (8)
        CHARSXP (9)
        LGLSXP (10)
        INTSXP (13)
        REALSXP (14)
        CPLXSXP (15)
        STRSXP (16)
        DOTSXP (17)
        VECSXP (19)
        EXPRSXP (20)
        BCODESXP (21)
        EXTPTRSXP (22)
        WEAKREFSXP (23)
        RAWSXP (24)
        OBJSXP (25)
        ALTREP_SXP (238)
        BASEENV_SXP (241)
        EMPTYENV_SXP (242)
        MISSINGARG_SXP (251)
        GLOBALENV_SXP (253)
        NILVALUE_SXP (254)
        REFSXP (255)
    end
end
