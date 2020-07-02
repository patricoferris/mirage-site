FROM ocaml/opam2:4.10
RUN sudo apt-get update
RUN opam update -y
RUN sudo apt-get install m4 -y
RUN opam install mirage -y 
RUN eval $(opam env)
RUN mkdir /home/opam/website
COPY --chown=opam ./ /home/opam/website
WORKDIR /home/opam/website

# HACK: Until ocaml-git is fixed, use modified Irmin
RUN git clone https://github.com/patricoferris/irmin.git 
WORKDIR /home/opam/website/irmin
RUN git checkout mirage-site
RUN opam pin add irmin-git . -y 

WORKDIR /home/opam/website/src
RUN opam config exec -- mirage configure -t unix
RUN make depends
RUN opam config exec -- mirage build
CMD ["/bin/bash"]
