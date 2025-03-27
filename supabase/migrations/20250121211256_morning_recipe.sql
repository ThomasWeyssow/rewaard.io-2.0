/*
  # Mise à jour du mot de passe de Nicolas

  1. Changements
    - Met à jour le mot de passe de l'utilisateur nicolas@gmail.com vers 'Toto1998!'
*/

UPDATE auth.users
SET encrypted_password = crypt('Toto1998!', gen_salt('bf'))
WHERE email = 'nicolas@gmail.com';