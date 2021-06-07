for d in ./modules/*/ 
  do (cd "$d" && terraform-docs markdown table .)
done
