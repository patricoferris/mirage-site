FROM ocaml/opam2:4.10
RUN sudo apt-get update
RUN opam update -y
RUN sudo apt-get install m4 -y
RUN opam install mirage -y 
RUN eval $(opam env)
RUN mkdir /home/opam/website
COPY --chown=opam ./ /home/opam/website
WORKDIR /home/opam/website/src 
RUN ls && pwd
RUN opam config exec -- mirage configure -t unix
RUN make depends
RUN opam config exec -- mirage build
CMD ["/bin/bash"]
