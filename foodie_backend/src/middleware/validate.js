function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source]);
    if (!result.success) {
      const issues = result.error.issues || result.error.errors || [];
      const firstIssue = issues[0];
      const message = firstIssue 
        ? `${firstIssue.path.length ? firstIssue.path.join('.') + ': ' : ''}${firstIssue.message}`
        : 'Validation error';
      return res.status(400).json({ error: message });
    }
    req[source] = result.data;
    next();
  };
}

module.exports = validate;
