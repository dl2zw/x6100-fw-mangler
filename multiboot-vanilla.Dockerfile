# (C) 2023 Joerg Jungermann, GPLv2 see LICENSE

FROM x6100:xiegu-vanilla AS xiegu
FROM x6100:r1cbu-vanilla AS r1cbu
FROM x6100:k4vz-r1cbu-vanilla AS k4vz-r1cbu

FROM x6100:multiboot

  COPY --from=xiegu /target /target/Xiegu
  COPY --from=r1cbu /target /target/R1CBU
  COPY --from=k4vz-r1cbu /target /target/K4VZ-R1CBU

  RUN set -e ;\
    : set -x ;\
    cd /target ;\
    ln -s Xiegu Default ;\
    ln -s R1CBU Button1 ;\
    ln -s K4VZ-R1CBU Button2 ;\
    ln -s Xiegu Button3 ;\
    ln -s Xiegu Button4 ;\
    ln -s Xiegu Button5 ;\
  : # eo RUN

# vim: foldmethod=indent
