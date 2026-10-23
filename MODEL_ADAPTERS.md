# Model Object Support

This reader imports supported data stored in R&reg; serialization files. It
does not reconstruct fitted R models as executable MATLAB&reg; predictive-model
objects.

Many R model objects are lists with class attributes. The reader may recover
supported components as dictionaries, tables, cells, and arrays. Unsupported
components produce an error by default, diagnostic placeholders with
`PreserveUnsupported="opaque"`, or an unstable parsed representation with
`PreserveUnsupported="raw"`.

Recovering a model's stored components does not implement its methods, package
code, formula handling, preprocessing, or prediction behavior. Do not use the
returned components as a substitute for an equivalent validated model.

## Interpreting imported model data

- Check the source object's class and package/version before interpreting its
  fields.
- Use metadata to inspect attributes, factor levels, dimensions, and missing
  values.
- Validate any calculations based on extracted fields against the originating
  application.
- Raw diagnostic structures are not a stable interchange format.

There is no generic conversion from an R fitted model to an executable
prediction model. The supported data conversions are listed in
[README.md](README.md).

<!-- Copyright 2026 The MathWorks, Inc. -->
