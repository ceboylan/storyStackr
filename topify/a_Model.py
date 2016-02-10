def ModelIt(fromUser  = 'Default', topics = []):
  in_month = len(births)
  print 'The number born is %i' % in_month
  result = in_month
  if fromUser != 'Default':
    return result
  else:
    return 'check your input'