FROM python:3.8

RUN apt-get install apt-transport-https && \
    echo "deb https://notesalexp.org/tesseract-ocr/buster/ buster main" >> /etc/apt/sources.list && \
    wget -O - https://notesalexp.org/debian/alexp_key.asc | apt-key add -

RUN apt-get update && \
    apt-get install --yes locales build-essential libpoppler-cpp-dev python3-dev \
    python3-distutils poppler-utils libpoppler-qt5-1 poppler-data libleptonica-dev \
    libtesseract-dev tesseract-ocr pkg-config cmake wget curl \
    default-jre libreoffice libreoffice-java-common && rm -rf /var/lib/apt/lists/*

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

RUN pip install poetry

RUN mkdir mmcv && wget -P mmcv https://download.openmmlab.com/mmcv/dist/1.2.1/torch1.7.0/cpu/mmcv_full-1.2.1%2Btorch1.7.0%2Bcpu-cp38-cp38-manylinux1_x86_64.whl

COPY poetry.lock /
COPY pyproject.toml /
COPY poetry.lock /

RUN poetry config virtualenvs.create false && \
    poetry add mmcv/mmcv_full-1.2.1+torch1.7.0+cpu-cp38-cp38-manylinux1_x86_64.whl \
    && poetry install --no-interaction \
    && rm -rf poetry.lock pyproject.toml poetry.lock mmcv/

RUN pip install 'git+https://github.com/open-mmlab/mmdetection.git@v2.7.0'

RUN python -m nltk.downloader stopwords && \
    python -m nltk.downloader words && \
    python -m nltk.downloader punkt && \
    python -m nltk.downloader wordnet

RUN mkdir /models && \
    gdown "https://drive.google.com/uc?id=17Xtqh3X9_Hu4BWFTiJpgmYipouFMy0sG" -O /models/epoch_20_w18.pth && \
    wget --output-document /models/ch_ppocr_mobile_v2.0_det_infer.tar https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_det_infer.tar && \
    tar xf /models/ch_ppocr_mobile_v2.0_det_infer.tar -C /models && \
    rm -rf /models/ch_ppocr_mobile_v2.0_det_infer.tar && \
    wget --output-document /models/ch_ppocr_server_v2.0_det_infer.tar https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_server_v2.0_det_infer.tar && \
    tar xf /models/ch_ppocr_server_v2.0_det_infer.tar -C /models && \
    rm -rf /models/ch_ppocr_server_v2.0_det_infer.tar && \
    wget --output-document /models/ch_ppocr_mobile_v2.0_cls_infer.tar https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar && \
    tar xf /models/ch_ppocr_mobile_v2.0_cls_infer.tar -C /models && \
    rm -rf /models/ch_ppocr_mobile_v2.0_cls_infer.tar


ENV CASCADE_MODEL_PATH="/models/epoch_20_w18.pth"
ENV PADDLE_MODEL_DIR="/models/ch_ppocr_server_v2.0_det_infer"
ENV PADDLE_MODEL_CLS="/models/ch_ppocr_server_v2.0_cls_infer"

COPY . /table-extractor
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH="${PYTHONPATH}:/table-extractor"

WORKDIR /table-extractor

CMD ["/bin/bash"]