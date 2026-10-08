# (C) 2023 Joerg Jungermann, GPLv2 see LICENSE
# (C) 2026 DL2ZW

FROM x6100:xiegu-vanilla AS xiegu
FROM x6100:r1cbu-vanilla AS r1cbu
FROM x6100:k4vz-r1cbu-vanilla AS k4vz-r1cbu

FROM x6100:multiboot

  COPY img-mangler/multiboot-vanillafy.sh /src/img-mangler/

  COPY --from=xiegu /target /target/Xiegu
  COPY --from=r1cbu /target /target/R1CBU
  COPY --from=k4vz-r1cbu /target /target/K4VZ-R1CBU

  COPY --from=xiegu      /orig-dev.tar /tmp/orig-dev/Xiegu.tar
  COPY --from=r1cbu      /orig-dev.tar /tmp/orig-dev/R1CBU.tar
  COPY --from=k4vz-r1cbu /orig-dev.tar /tmp/orig-dev/K4VZ-R1CBU.tar

  # undo build-only changes, keep the firmware as shipped
  RUN set -e ;\
    : set -x ;\
    for fw in Xiegu R1CBU K4VZ-R1CBU; do \
      sh -e /src/img-mangler/multiboot-vanillafy.sh /target/$fw /tmp/orig-dev/$fw.tar ;\
    done ;\
    rm -rf /tmp/orig-dev ;\
  : # eo RUN

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
