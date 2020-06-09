FROM ocaml/opam2:4.10
RUN sudo apt-get update
RUN mkdir site
RUN git clone https://github.com/patricoferris/mirage-site ./site 
RUN opam update -y
RUN sudo apt-get install m4 -y
WORKDIR site/src
RUN opam install mirage -y 
RUN git pull && git pull
RUN opam config exec -- mirage configure -t unix
RUN make depends
RUN opam config exec -- mirage build
CMD ["sudo", "_build/main.native"]