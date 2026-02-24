{
  ...
}:

{
  # Create a "secrets" file with the given text content.
  # text (str): the content of the file
  # returns: attrset usable directly in environment.etc
  makeEtcSecretFile = text: {
    text = text;
    mode = "0600";
    user = "root";
    group = "root";
  };
}
